// OutlineTests.swift
// Tests for PDF outline/bookmark generation with H<N> wrapper

import CSS
import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

// MARK: - H<N> Wrapper (reproduces rule-legal behavior)

/// Generic heading wrapper that applies `.css.pageBreakAfter(.avoid)` to keep headings with following content.
/// This is the same pattern used in rule-legal documents.
public struct H<let N: Int> {
    public init() {}

    @HTML.Builder
    public func callAsFunction(
        @HTML.Builder _ content: () -> some HTML.View
    ) -> some HTML.View {
        switch N {
        case 1: H1 { content() }.css.pageBreakAfter(.avoid)
        case 2: H2 { content() }.css.pageBreakAfter(.avoid)
        case 3: H3 { content() }.css.pageBreakAfter(.avoid)
        case 4: H4 { content() }.css.pageBreakAfter(.avoid)
        case 5: H5 { content() }.css.pageBreakAfter(.avoid)
        case 6: H6 { content() }.css.pageBreakAfter(.avoid)
        default: H1 { content() }.css.pageBreakAfter(.avoid)
        }
    }
}

// MARK: - Outline Tests

@Suite
struct `Outline Generation Tests` {

    @Test
    func `Raw H1 headings appear in outline`() throws {
        let result = PDF.HTML.render {
            H1 { "Main Title" }
            Paragraph { "Some content after the title." }
        }

        print("DEBUG TEST: Raw H1 - collected \(result.headings.count) headings")
        for h in result.headings {
            print("DEBUG TEST: - Level \(h.level): '\(h.text)' page \(h.pageNumber)")
        }

        #expect(result.headings.count >= 1, "Should collect at least 1 heading")
        #expect(result.headings.contains { $0.text == "Main Title" }, "Should contain 'Main Title'")
    }

    @Test
    func `H wrapper headings appear in outline`() throws {
        let result = PDF.HTML.render {
            H<1>() { "Wrapped Title" }
            Paragraph { "Some content after the wrapped title." }
        }

        print("DEBUG TEST: H<1> wrapper - collected \(result.headings.count) headings")
        for h in result.headings {
            print("DEBUG TEST: - Level \(h.level): '\(h.text)' page \(h.pageNumber)")
        }

        #expect(result.headings.count >= 1, "Should collect at least 1 heading from H<N> wrapper")
        #expect(result.headings.contains { $0.text == "Wrapped Title" }, "Should contain 'Wrapped Title'")
    }

    @Test
    func `Raw H1 inside Header container appears in outline`() throws {
        let result = PDF.HTML.render {
            Header {
                H1 { "Header Title" }
                Paragraph { "(A subtitle)" }
            }
            Paragraph { "Body content." }
        }

        print("DEBUG TEST: Raw H1 inside Header - collected \(result.headings.count) headings")
        for h in result.headings {
            print("DEBUG TEST: - Level \(h.level): '\(h.text)' page \(h.pageNumber)")
        }

        #expect(result.headings.count >= 1, "Should collect at least 1 heading from Header container")
        #expect(result.headings.contains { $0.text == "Header Title" }, "Should contain 'Header Title'")
    }

    @Test
    func `Mixed raw and wrapped headings all appear in outline`() throws {
        let result = PDF.HTML.render {
            // Raw H1 in Header (like documentHeader)
            Header {
                H1 { "DOCUMENT TITLE" }
                Paragraph { "(A Corporation)" }
            }

            // Wrapped H3 (like articleI)
            Section {
                H<3>() { "ARTICLE I" }
                H<4>() { "NAME" }
                Paragraph { "The name of this corporation is Test Corp." }
            }

            // Another wrapped section
            Section {
                H<3>() { "ARTICLE II" }
                H<4>() { "PURPOSE" }
                Paragraph { "The purpose of this corporation is testing." }
            }
        }

        print("DEBUG TEST: Mixed headings - collected \(result.headings.count) headings")
        for h in result.headings {
            print("DEBUG TEST: - Level \(h.level): '\(h.text)' page \(h.pageNumber)")
        }

        // Should have all headings
        #expect(result.headings.count >= 5, "Should collect at least 5 headings")
        #expect(result.headings.contains { $0.text == "DOCUMENT TITLE" }, "Should contain 'DOCUMENT TITLE'")
        #expect(result.headings.contains { $0.text == "ARTICLE I" }, "Should contain 'ARTICLE I'")
        #expect(result.headings.contains { $0.text == "ARTICLE II" }, "Should contain 'ARTICLE II'")
        #expect(result.headings.contains { $0.text == "NAME" }, "Should contain 'NAME'")
        #expect(result.headings.contains { $0.text == "PURPOSE" }, "Should contain 'PURPOSE'")
    }

    @Test
    func `Document with outline generates correct PDF`() throws {
        let doc = PDF.Document(
            info: .init(title: "Outline Test"),
            generateOutline: true
        ) {
            Header {
                H1 { "MAIN DOCUMENT TITLE" }
                Paragraph { "(Subtitle)" }
            }

            Section {
                H<3>() { "SECTION ONE" }
                Paragraph { "Content for section one." }
            }

            Section {
                H<3>() { "SECTION TWO" }
                Paragraph { "Content for section two." }
            }
        }

        let bytes = [UInt8](doc)

        // Write to /tmp for visual inspection
        let url = URL(fileURLWithPath: "/tmp/outline-test.pdf")
        try Data(bytes).write(to: url)
        print("DEBUG TEST: PDF written to: \(url.path)")

        #expect(doc.pages.count >= 1)
        #expect(doc.outline != nil, "Document should have outline")

        if let outline = doc.outline {
            print("DEBUG TEST: Outline has \(outline.items.count) top-level items")
            printOutlineItems(outline.items, indent: 0)

            // The main title should be in the outline
            let hasMainTitle = containsTitle(outline.items, "MAIN DOCUMENT TITLE")
            #expect(hasMainTitle, "Outline should contain 'MAIN DOCUMENT TITLE'")
        }
    }

    @Test
    func `H1 with BR elements inside`() throws {
        let result = PDF.HTML.render {
            Header {
                H1 {
                    "ARTICLES OF INCORPORATION"
                    BR()
                    "OF"
                    BR()
                    "TEST CORPORATION"
                }.css.textAlign(.center)
            }
            Paragraph { "Body content." }
        }

        print("DEBUG TEST: H1 with BR - collected \(result.headings.count) headings")
        for h in result.headings {
            print("DEBUG TEST: - Level \(h.level): '\(h.text)' page \(h.pageNumber)")
        }

        #expect(result.headings.count >= 1, "Should collect at least 1 heading from H1 with BR elements")
        // The text should be extracted (even if it's just the first part)
        let hasH1 = result.headings.contains { h in
            h.level == 1 && !h.text.isEmpty
        }
        #expect(hasH1, "Should have an H1 heading with non-empty text")
    }

    @Test
    func `Articles of Incorporation style document`() throws {
        let doc = PDF.Document(
            info: .init(title: "Articles of Incorporation"),
            generateOutline: true
        ) {
            // documentHeader style - EXACTLY like the real document
            Header {
                H1 {
                    "ARTICLES OF INCORPORATION"
                    BR()
                    "OF"
                    BR()
                    "TEST CORPORATION, INC."
                }.css.textAlign(.center)
                Paragraph { "(A Nevada Corporation)" }.css.textAlign(.center)
                Paragraph { "(Pursuant to Chapter 78 of the Nevada Revised Statutes)" }.css.textAlign(.center)
            }

            // Article sections using H<N> wrapper
            Section {
                H<3>() { "ARTICLE I" }
                H<4>() { "NAME" }
                Paragraph { "The name of this corporation is TEST CORPORATION, INC." }
            }

            Section {
                H<3>() { "ARTICLE II" }
                H<4>() { "REGISTERED AGENT" }
                Paragraph { "The registered agent is located at 123 Main Street." }
            }

            Section {
                H<3>() { "ARTICLE III" }
                H<4>() { "PURPOSE" }
                Paragraph { "The purpose is to engage in any lawful activity." }
            }
        }

        let bytes = [UInt8](doc)

        // Write to /tmp for visual inspection
        let url = URL(fileURLWithPath: "/tmp/articles-of-incorporation-test.pdf")
        try Data(bytes).write(to: url)
        print("DEBUG TEST: PDF written to: \(url.path)")

        #expect(doc.outline != nil, "Document should have outline")

        if let outline = doc.outline {
            print("DEBUG TEST: Final outline structure:")
            printOutlineItems(outline.items, indent: 0)

            // Check for expected items
            let hasArticlesTitle = containsTitle(outline.items, "ARTICLES OF INCORPORATION OF TEST CORPORATION, INC.")
            let hasArticleI = containsTitle(outline.items, "ARTICLE I")
            let hasArticleII = containsTitle(outline.items, "ARTICLE II")
            let hasArticleIII = containsTitle(outline.items, "ARTICLE III")

            #expect(hasArticlesTitle, "Outline should contain 'ARTICLES OF INCORPORATION'")
            #expect(hasArticleI, "Outline should contain 'ARTICLE I'")
            #expect(hasArticleII, "Outline should contain 'ARTICLE II'")
            #expect(hasArticleIII, "Outline should contain 'ARTICLE III'")
        }
    }
}

// MARK: - Helper Functions

private func printOutlineItems(_ items: [ISO_32000.Outline.Item], indent: Int) {
    let prefix = String(repeating: "  ", count: indent)
    for item in items {
        print("\(prefix)- \(item.title)")
        if !item.children.isEmpty {
            printOutlineItems(item.children, indent: indent + 1)
        }
    }
}

private func containsTitle(_ items: [ISO_32000.Outline.Item], _ title: String) -> Bool {
    for item in items {
        if item.title == title {
            return true
        }
        if containsTitle(item.children, title) {
            return true
        }
    }
    return false
}

// MARK: - Diagnostic Tests for Single vs Multiple H1

@Suite
struct `Single vs Multiple H1 Diagnostic Tests` {

    @Test
    func `Single H1 with H3 children - check if parent shows`() throws {
        let doc = PDF.Document(
            info: .init(title: "Single H1 Parent Test"),
            generateOutline: true
        ) {
            // Single H1 parent with H3 children (like Articles of Incorporation)
            H1 { "DOCUMENT TITLE" }

            Section {
                H3 { "Section 1" }
                Paragraph { "Content for section 1." }
            }

            Section {
                H3 { "Section 2" }
                Paragraph { "Content for section 2." }
            }

            Section {
                H3 { "Section 3" }
                Paragraph { "Content for section 3." }
            }
        }

        let url = URL(fileURLWithPath: "/tmp/single-h1-parent-test.pdf")
        try Data([UInt8](doc)).write(to: url)
        print("Single H1 PDF written to: \(url.path)")

        if let outline = doc.outline {
            print("Single H1 outline structure:")
            printOutlineItems(outline.items, indent: 0)
            print("Top-level items count: \(outline.items.count)")
        }
    }

    @Test
    func `Multiple H1s - check if all parents show`() throws {
        let doc = PDF.Document(
            info: .init(title: "Multiple H1 Parents Test"),
            generateOutline: true
        ) {
            // First H1 with H3 children
            H1 { "FIRST DOCUMENT" }

            Section {
                H3 { "First Section 1" }
                Paragraph { "Content." }
            }

            Section {
                H3 { "First Section 2" }
                Paragraph { "Content." }
            }

            // Second H1 with H3 children
            H1 { "SECOND DOCUMENT" }

            Section {
                H3 { "Second Section 1" }
                Paragraph { "Content." }
            }

            Section {
                H3 { "Second Section 2" }
                Paragraph { "Content." }
            }
        }

        let url = URL(fileURLWithPath: "/tmp/multiple-h1-parents-test.pdf")
        try Data([UInt8](doc)).write(to: url)
        print("Multiple H1 PDF written to: \(url.path)")

        if let outline = doc.outline {
            print("Multiple H1 outline structure:")
            printOutlineItems(outline.items, indent: 0)
            print("Top-level items count: \(outline.items.count)")
        }
    }
}
