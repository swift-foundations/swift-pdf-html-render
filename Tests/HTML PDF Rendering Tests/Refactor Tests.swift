// Refactor Tests.swift
// Tests for the two-phase HTML → PDF transformation

import CSS
import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import HTML_PDF_Rendering

@Suite
struct `PDF.HTML.View Tests` {

    // MARK: - Basic Transformation

    @Test
    func `String transforms to PDF content`() {
        let html = "Hello, World!"
        let (pages, _) = PDF.HTML.pages {
            html
        }

        // Should have at least one page
        #expect(pages.count >= 1)
    }

    @Test
    func `Paragraph transforms with spacing`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Test paragraph" }
            }
        }

        let (pages, _) = PDF.HTML.pages(html: TestView.init)

        // Should have operations
        let ops = pages.first ?? []
        let textOps = ops.filter {
            if case .text = $0 { return true }
            return false
        }
        #expect(textOps.count >= 1)
    }

    @Test
    func `Heading transforms with larger font`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                H1 { "Big Heading" }
            }
        }

        let (pages, _) = PDF.HTML.pages(html: TestView.init)
        let ops = pages.first ?? []

        // Should have text operations
        let textOps = ops.compactMap { op -> PDF.Render.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(textOps.count >= 1)

        // H1 should use larger font size (2x default)
        if let firstOp = textOps.first {
            let config = PDF.HTML.Configuration()
            let expectedSize = config.headingSize(level: 1)
            #expect(firstOp.size == expectedSize)
        }
    }

    // MARK: - Inline Flow

    @Test
    func `Inline elements stay on same line`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    "Normal "
                    StrongImportance { "bold" }
                    " normal"
                }
            }
        }

        let (pages, _) = PDF.HTML.pages(html: TestView.init)
        let ops = pages.first ?? []

        // Get all text operations
        let textOps = ops.compactMap { op -> PDF.Render.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        // All text should be on the same Y position (same line)
        let yPositions = Set(textOps.map { Int($0.position.y.value.value) })
        #expect(
            yPositions.count == 1,
            "Expected all text on same line, got Y positions: \(yPositions)"
        )
    }

    @Test
    func `Bold applies correct font variant`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    StrongImportance { "Bold text" }
                }
            }
        }

        let (pages, _) = PDF.HTML.pages(html: TestView.init)
        let ops = pages.first ?? []

        let textOps = ops.compactMap { op -> PDF.Render.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(textOps.count >= 1)

        // Should use bold font
        if let op = textOps.first {
            #expect(op.font == PDF.Font.helvetica.bold)
        }
    }

    @Test
    func `Italic applies correct font variant`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    Emphasis { "Italic text" }
                }
            }
        }

        let (pages, _) = PDF.HTML.pages {
            TestView()
        }
        let ops = pages.first ?? []

        let textOps = ops.compactMap { op -> PDF.Render.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(textOps.count >= 1)

        // Should use italic font
        if let op = textOps.first {
            #expect(op.font == PDF.Font.helvetica.italic)
        }
    }

    @Test
    func `Bold + Italic combines correctly`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    StrongImportance {
                        Emphasis { "Bold italic" }
                    }
                }
            }
        }

        let (pages, _) = PDF.HTML.pages(html: TestView.init)
        let ops = pages.first ?? []

        let textOps = ops.compactMap { op -> PDF.Render.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(textOps.count >= 1)

        // Should use bold italic font
        if let op = textOps.first {
            #expect(op.font == PDF.Font.helvetica.bold.italic)
        }
    }

    // MARK: - Document Creation

    @Test
    func `PDF.Document can be created from HTML`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                H1 { "Title" }
                Paragraph { "Content" }
            }
        }

        let doc = PDF.Document(info: .init(title: "Test")) {
            TestView()
        }

        #expect(doc.pages.count >= 1)
        #expect(doc.info?.title == "Test")
    }

    @Test
    func `PDF bytes can be generated from HTML`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Hello PDF" }
            }
        }

        let doc = PDF.Document { TestView() }
        let bytes = [UInt8](doc)

        // Should start with %PDF
        #expect(!bytes.isEmpty)
        #expect(bytes.starts(with: [.ascii.percentSign, .ascii.P, .ascii.D, .ascii.F]))
    }

    // MARK: - Configuration

    @Test
    func `Configuration affects heading sizes`() {
        let config = PDF.HTML.Configuration(defaultFontSize: 14)

        #expect(config.headingSize(level: 1) == 28)  // 14 * 2.0
        #expect(config.headingSize(level: 2) == 21)  // 14 * 1.5
        // Note: Integer literals work via ExpressibleByIntegerLiteral, but computed
        // Double expressions like `14 * 1.17` require explicit wrapping in Unit.
        // This is a quirk of Swift Testing's #expect macro - a regular `if` statement
        // would handle the implicit BinaryFloatingPoint conversion correctly.
        #expect(config.headingSize(level: 3) == PDF.UserSpace.Unit(14 * 1.17))
    }

    @Test
    func `Configuration affects content dimensions`() {
        let config = PDF.HTML.Configuration(
            paperSize: .a4,
            margins: .init(top: 72, leading: 72, bottom: 72, trailing: 72)
        )

        #expect(config.contentWidth == PDF.UserSpace.Rectangle.a4.width.value - 144)
        #expect(config.contentHeight == PDF.UserSpace.Rectangle.a4.height.value - 144)
    }
}

// MARK: - Sticky Header Tests

@Suite("Sticky Header Tests")
struct StickyHeaderTests {

    // Helper to find text operations on each page
    private func findText(_ needle: String, in pages: [[PDF.Render.Operation]]) -> [(page: Int, y: PDF.UserSpace.Unit)] {
        var results: [(page: Int, y: PDF.UserSpace.Unit)] = []
        for (pageIndex, page) in pages.enumerated() {
            for op in page {
                if case .text(let textOp) = op, textOp.text.contains(needle) {
                    results.append((pageIndex, textOp.position.y.value))
                }
            }
        }
        return results
    }

    // Helper to check if two items are on the same page
    private func assertSamePage(_ item1: String, _ item2: String, in pages: [[PDF.Render.Operation]], file: StaticString = #file, line: UInt = #line) {
        let pos1 = findText(item1, in: pages).first
        let pos2 = findText(item2, in: pages).first
        #expect(pos1 != nil, "Should find '\(item1)'")
        #expect(pos2 != nil, "Should find '\(item2)'")
        if let p1 = pos1, let p2 = pos2 {
            #expect(p1.page == p2.page, "'\(item1)' (page \(p1.page + 1)) and '\(item2)' (page \(p2.page + 1)) should be on same page")
        }
    }

    @Test("Basic sticky header moves to next page with content")
    func basicStickyHeader() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill most of page 1
                Paragraph { "Filler 1" }
                Paragraph { "Filler 2" }
                Paragraph { "Filler 3" }
                Paragraph { "Filler 4" }
                Paragraph { "Filler 5" }
                Paragraph { "Filler 6" }
                Paragraph { "Filler 7" }
                Paragraph { "Filler 8" }
                Paragraph { "Filler 9" }
                Paragraph { "Filler 10" }
                Paragraph { "Filler 11" }
                Paragraph { "Filler 12" }
                Paragraph { "Filler 13" }
                Paragraph { "Filler 14" }
                Paragraph { "Filler 15" }
                Paragraph { "Filler 16" }
                Paragraph { "Filler 17" }
                Paragraph { "Filler 18" }
                Paragraph { "Filler 19" }
                Paragraph { "Filler 20" }
                Paragraph { "Filler 21" }
                Paragraph { "Filler 22" }
                Paragraph { "Filler 23" }
                Paragraph { "Filler 24" }
                Paragraph { "Filler 25" }
                Paragraph { "Filler 26" }
                Paragraph { "Filler 27" }
                Paragraph { "Filler 28" }
                Paragraph { "Filler 29" }
                Paragraph { "Filler 30" }
                Paragraph { "Filler 31" }
                Paragraph { "Filler 32" }
                Paragraph { "Filler 33" }
                Paragraph { "Filler 34" }
                Paragraph { "Filler 35" }
                Paragraph { "Filler 36" }
                Paragraph { "Filler 37" }
                Paragraph { "Filler 38" }
                Paragraph { "Filler 39" }
                Paragraph { "Filler 40" }

                H2 { "STICKY_HEADER" }
                    .css.pageBreakAfter(.avoid)

                Paragraph { "FOLLOWING_CONTENT" }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }
        assertSamePage("STICKY_HEADER", "FOLLOWING_CONTENT", in: pages)
    }

    @Test("Sticky header with plenty of room stays on current page")
    func stickyHeaderFitsOnPage() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Some content before" }

                H2 { "HEADER_FITS" }
                    .css.pageBreakAfter(.avoid)

                Paragraph { "CONTENT_FITS" }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        // Both should be on page 1
        let headerPos = findText("HEADER_FITS", in: pages).first
        let contentPos = findText("CONTENT_FITS", in: pages).first

        #expect(headerPos?.page == 0, "Header should be on page 1")
        #expect(contentPos?.page == 0, "Content should be on page 1")
    }

    @Test("Consecutive sticky headers chain together")
    func consecutiveStickyHeaders() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill most of page
                Paragraph { "Filler 1" }
                Paragraph { "Filler 2" }
                Paragraph { "Filler 3" }
                Paragraph { "Filler 4" }
                Paragraph { "Filler 5" }
                Paragraph { "Filler 6" }
                Paragraph { "Filler 7" }
                Paragraph { "Filler 8" }
                Paragraph { "Filler 9" }
                Paragraph { "Filler 10" }
                Paragraph { "Filler 11" }
                Paragraph { "Filler 12" }
                Paragraph { "Filler 13" }
                Paragraph { "Filler 14" }
                Paragraph { "Filler 15" }
                Paragraph { "Filler 16" }
                Paragraph { "Filler 17" }
                Paragraph { "Filler 18" }
                Paragraph { "Filler 19" }
                Paragraph { "Filler 20" }
                Paragraph { "Filler 21" }
                Paragraph { "Filler 22" }
                Paragraph { "Filler 23" }
                Paragraph { "Filler 24" }
                Paragraph { "Filler 25" }
                Paragraph { "Filler 26" }
                Paragraph { "Filler 27" }
                Paragraph { "Filler 28" }
                Paragraph { "Filler 29" }
                Paragraph { "Filler 30" }
                Paragraph { "Filler 31" }
                Paragraph { "Filler 32" }
                Paragraph { "Filler 33" }
                Paragraph { "Filler 34" }
                Paragraph { "Filler 35" }
                Paragraph { "Filler 36" }
                Paragraph { "Filler 37" }
                Paragraph { "Filler 38" }

                // Two consecutive sticky headers
                H2 { "FIRST_STICKY" }
                    .css.pageBreakAfter(.avoid)

                H3 { "SECOND_STICKY" }
                    .css.pageBreakAfter(.avoid)

                Paragraph { "FINAL_CONTENT" }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        // All three should be on the same page
        assertSamePage("FIRST_STICKY", "SECOND_STICKY", in: pages)
        assertSamePage("SECOND_STICKY", "FINAL_CONTENT", in: pages)
    }

    @Test("Sticky header at document end renders correctly")
    func stickyHeaderAtDocumentEnd() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Some content" }

                // Sticky header with no following content
                H2 { "ORPHAN_HEADER" }
                    .css.pageBreakAfter(.avoid)
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        // Header should still be rendered
        let headerPos = findText("ORPHAN_HEADER", in: pages)
        #expect(!headerPos.isEmpty, "Orphan sticky header should be rendered")
    }

    @Test("Non-sticky header can be orphaned at page bottom")
    func nonStickyHeaderCanBeOrphaned() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill most of page
                Paragraph { "Filler 1" }
                Paragraph { "Filler 2" }
                Paragraph { "Filler 3" }
                Paragraph { "Filler 4" }
                Paragraph { "Filler 5" }
                Paragraph { "Filler 6" }
                Paragraph { "Filler 7" }
                Paragraph { "Filler 8" }
                Paragraph { "Filler 9" }
                Paragraph { "Filler 10" }
                Paragraph { "Filler 11" }
                Paragraph { "Filler 12" }
                Paragraph { "Filler 13" }
                Paragraph { "Filler 14" }
                Paragraph { "Filler 15" }
                Paragraph { "Filler 16" }
                Paragraph { "Filler 17" }
                Paragraph { "Filler 18" }
                Paragraph { "Filler 19" }
                Paragraph { "Filler 20" }
                Paragraph { "Filler 21" }
                Paragraph { "Filler 22" }
                Paragraph { "Filler 23" }
                Paragraph { "Filler 24" }
                Paragraph { "Filler 25" }
                Paragraph { "Filler 26" }
                Paragraph { "Filler 27" }
                Paragraph { "Filler 28" }
                Paragraph { "Filler 29" }
                Paragraph { "Filler 30" }
                Paragraph { "Filler 31" }
                Paragraph { "Filler 32" }
                Paragraph { "Filler 33" }
                Paragraph { "Filler 34" }
                Paragraph { "Filler 35" }
                Paragraph { "Filler 36" }
                Paragraph { "Filler 37" }
                Paragraph { "Filler 38" }
                Paragraph { "Filler 39" }
                Paragraph { "Filler 40" }

                // NON-sticky header (no .css.pageBreakAfter(.avoid))
                H2 { "NORMAL_HEADER" }

                Paragraph { "NORMAL_CONTENT that is long enough to wrap to multiple lines and will definitely cause a page break when combined with the header above." }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        // Without sticky, header and content may be on different pages
        let headerPos = findText("NORMAL_HEADER", in: pages).first
        let contentPos = findText("NORMAL_CONTENT", in: pages).first

        #expect(headerPos != nil, "Should find header")
        #expect(contentPos != nil, "Should find content")
        // Note: They might be on different pages - that's expected for non-sticky
    }

    @Test("Sticky header with different heading levels")
    func stickyHeaderDifferentLevels() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                H1 { "H1_STICKY" }.css.pageBreakAfter(.avoid)
                Paragraph { "After H1" }

                H2 { "H2_STICKY" }.css.pageBreakAfter(.avoid)
                Paragraph { "After H2" }

                H3 { "H3_STICKY" }.css.pageBreakAfter(.avoid)
                Paragraph { "After H3" }

                H4 { "H4_STICKY" }.css.pageBreakAfter(.avoid)
                Paragraph { "After H4" }

                H5 { "H5_STICKY" }.css.pageBreakAfter(.avoid)
                Paragraph { "After H5" }

                H6 { "H6_STICKY" }.css.pageBreakAfter(.avoid)
                Paragraph { "After H6" }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        // Each heading should be on same page as its following paragraph
        assertSamePage("H1_STICKY", "After H1", in: pages)
        assertSamePage("H2_STICKY", "After H2", in: pages)
        assertSamePage("H3_STICKY", "After H3", in: pages)
        assertSamePage("H4_STICKY", "After H4", in: pages)
        assertSamePage("H5_STICKY", "After H5", in: pages)
        assertSamePage("H6_STICKY", "After H6", in: pages)
    }

    @Test("Sticky on non-heading block elements")
    func stickyOnNonHeadingElements() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill most of page
                Paragraph { "Filler 1" }
                Paragraph { "Filler 2" }
                Paragraph { "Filler 3" }
                Paragraph { "Filler 4" }
                Paragraph { "Filler 5" }
                Paragraph { "Filler 6" }
                Paragraph { "Filler 7" }
                Paragraph { "Filler 8" }
                Paragraph { "Filler 9" }
                Paragraph { "Filler 10" }
                Paragraph { "Filler 11" }
                Paragraph { "Filler 12" }
                Paragraph { "Filler 13" }
                Paragraph { "Filler 14" }
                Paragraph { "Filler 15" }
                Paragraph { "Filler 16" }
                Paragraph { "Filler 17" }
                Paragraph { "Filler 18" }
                Paragraph { "Filler 19" }
                Paragraph { "Filler 20" }
                Paragraph { "Filler 21" }
                Paragraph { "Filler 22" }
                Paragraph { "Filler 23" }
                Paragraph { "Filler 24" }
                Paragraph { "Filler 25" }
                Paragraph { "Filler 26" }
                Paragraph { "Filler 27" }
                Paragraph { "Filler 28" }
                Paragraph { "Filler 29" }
                Paragraph { "Filler 30" }
                Paragraph { "Filler 31" }
                Paragraph { "Filler 32" }
                Paragraph { "Filler 33" }
                Paragraph { "Filler 34" }
                Paragraph { "Filler 35" }
                Paragraph { "Filler 36" }
                Paragraph { "Filler 37" }
                Paragraph { "Filler 38" }

                // Sticky paragraph (unusual but should work)
                Paragraph { "STICKY_PARA" }
                    .css.pageBreakAfter(.avoid)

                Paragraph { "AFTER_STICKY_PARA" }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }
        assertSamePage("STICKY_PARA", "AFTER_STICKY_PARA", in: pages)
    }

    @Test("Multiple sticky headers across document")
    func multipleStickyHeadersAcrossDocument() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                H2 { "SECTION_1" }.css.pageBreakAfter(.avoid)
                Paragraph { "Content for section 1 that has enough text." }
                Paragraph { "More content for section 1." }
                Paragraph { "Even more content for section 1." }
                Paragraph { "Filler A1" }
                Paragraph { "Filler A2" }
                Paragraph { "Filler A3" }
                Paragraph { "Filler A4" }
                Paragraph { "Filler A5" }
                Paragraph { "Filler A6" }
                Paragraph { "Filler A7" }
                Paragraph { "Filler A8" }
                Paragraph { "Filler A9" }
                Paragraph { "Filler A10" }
                Paragraph { "Filler A11" }
                Paragraph { "Filler A12" }
                Paragraph { "Filler A13" }
                Paragraph { "Filler A14" }
                Paragraph { "Filler A15" }

                H2 { "SECTION_2" }.css.pageBreakAfter(.avoid)
                Paragraph { "Content for section 2." }
                Paragraph { "Filler B1" }
                Paragraph { "Filler B2" }
                Paragraph { "Filler B3" }
                Paragraph { "Filler B4" }
                Paragraph { "Filler B5" }
                Paragraph { "Filler B6" }
                Paragraph { "Filler B7" }
                Paragraph { "Filler B8" }
                Paragraph { "Filler B9" }
                Paragraph { "Filler B10" }
                Paragraph { "Filler B11" }
                Paragraph { "Filler B12" }
                Paragraph { "Filler B13" }
                Paragraph { "Filler B14" }
                Paragraph { "Filler B15" }

                H2 { "SECTION_3" }.css.pageBreakAfter(.avoid)
                Paragraph { "Content for section 3." }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        // Each section header should be with its content
        assertSamePage("SECTION_1", "Content for section 1", in: pages)
        assertSamePage("SECTION_2", "Content for section 2", in: pages)
        assertSamePage("SECTION_3", "Content for section 3", in: pages)
    }

    @Test("page-break-before moves sticky header with content to new page")
    func pageBreakBeforeWithStickyHeader() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "FIRST_PAGE_CONTENT" }

                H2 { "STICKY_BEFORE_BREAK" }
                    .css.pageBreakAfter(.avoid)

                // This has page-break-before which forces new page
                // The sticky header should move WITH content to the new page
                ContentDivision { Paragraph { "FORCED_NEW_PAGE" } }
                    .css.pageBreakBefore(.always)
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        let firstPos = findText("FIRST_PAGE_CONTENT", in: pages).first
        let headerPos = findText("STICKY_BEFORE_BREAK", in: pages).first
        let contentPos = findText("FORCED_NEW_PAGE", in: pages).first

        #expect(firstPos != nil)
        #expect(headerPos != nil)
        #expect(contentPos != nil)

        // The sticky header and its content should be on the same page (new page)
        // The first paragraph should be on page 0, header+content on page 1
        if let f = firstPos, let h = headerPos, let c = contentPos {
            #expect(f.page == 0, "First content should be on page 0")
            #expect(h.page == c.page, "Sticky header should move with content to new page")
            #expect(h.page > f.page, "Header+content should be on later page than first content")
        }
    }

    @Test("No text corruption or duplication with sticky headers")
    func noTextCorruption() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill page to trigger potential corruption
                Paragraph { "Filler 1" }
                Paragraph { "Filler 2" }
                Paragraph { "Filler 3" }
                Paragraph { "Filler 4" }
                Paragraph { "Filler 5" }
                Paragraph { "Filler 6" }
                Paragraph { "Filler 7" }
                Paragraph { "Filler 8" }
                Paragraph { "Filler 9" }
                Paragraph { "Filler 10" }
                Paragraph { "Filler 11" }
                Paragraph { "Filler 12" }
                Paragraph { "Filler 13" }
                Paragraph { "Filler 14" }
                Paragraph { "Filler 15" }
                Paragraph { "Filler 16" }
                Paragraph { "Filler 17" }
                Paragraph { "Filler 18" }
                Paragraph { "Filler 19" }
                Paragraph { "Filler 20" }
                Paragraph { "Filler 21" }
                Paragraph { "Filler 22" }
                Paragraph { "Filler 23" }
                Paragraph { "Filler 24" }
                Paragraph { "Filler 25" }
                Paragraph { "Filler 26" }
                Paragraph { "Filler 27" }
                Paragraph { "Filler 28" }
                Paragraph { "Filler 29" }
                Paragraph { "Filler 30" }
                Paragraph { "Filler 31" }
                Paragraph { "Filler 32" }
                Paragraph { "Filler 33" }
                Paragraph { "Filler 34" }
                Paragraph { "Filler 35" }
                Paragraph { "Filler 36" }
                Paragraph { "Filler 37" }
                Paragraph { "Filler 38" }
                Paragraph { "Filler 39" }
                Paragraph { "Filler 40" }

                H2 { "UNIQUE_HEADER_TEXT_12345" }
                    .css.pageBreakAfter(.avoid)

                Paragraph { "UNIQUE_CONTENT_TEXT_67890" }
            }
        }

        let (pages, _) = PDF.HTML.pages { TestView() }

        // Count occurrences of each unique text
        let headerMatches = findText("UNIQUE_HEADER_TEXT_12345", in: pages)
        let contentMatches = findText("UNIQUE_CONTENT_TEXT_67890", in: pages)

        // Each should appear exactly once (no duplication)
        #expect(headerMatches.count == 1, "Header should appear exactly once, found \(headerMatches.count)")
        #expect(contentMatches.count == 1, "Content should appear exactly once, found \(contentMatches.count)")
    }
}

// MARK: - Comprehensive Test

@Suite
struct `Comprehensive PDF.HTML.View Tests` {

    @Test
    func `sticky header stays with following content`() throws {
        // Create content that pushes sticky header to near bottom of page
        struct StickyHeaderTest: HTML.View {
            var body: some HTML.View {
                // Filler content to approach bottom of first page (40 lines should fill most of a page)
                Paragraph { "Filler line 1." }
                Paragraph { "Filler line 2." }
                Paragraph { "Filler line 3." }
                Paragraph { "Filler line 4." }
                Paragraph { "Filler line 5." }
                Paragraph { "Filler line 6." }
                Paragraph { "Filler line 7." }
                Paragraph { "Filler line 8." }
                Paragraph { "Filler line 9." }
                Paragraph { "Filler line 10." }
                Paragraph { "Filler line 11." }
                Paragraph { "Filler line 12." }
                Paragraph { "Filler line 13." }
                Paragraph { "Filler line 14." }
                Paragraph { "Filler line 15." }
                Paragraph { "Filler line 16." }
                Paragraph { "Filler line 17." }
                Paragraph { "Filler line 18." }
                Paragraph { "Filler line 19." }
                Paragraph { "Filler line 20." }
                Paragraph { "Filler line 21." }
                Paragraph { "Filler line 22." }
                Paragraph { "Filler line 23." }
                Paragraph { "Filler line 24." }
                Paragraph { "Filler line 25." }
                Paragraph { "Filler line 26." }
                Paragraph { "Filler line 27." }
                Paragraph { "Filler line 28." }
                Paragraph { "Filler line 29." }
                Paragraph { "Filler line 30." }
                Paragraph { "Filler line 31." }
                Paragraph { "Filler line 32." }
                Paragraph { "Filler line 33." }
                Paragraph { "Filler line 34." }
                Paragraph { "Filler line 35." }
                Paragraph { "Filler line 36." }
                Paragraph { "Filler line 37." }
                Paragraph { "Filler line 38." }
                Paragraph { "Filler line 39." }
                Paragraph { "Filler line 40." }

                // Sticky header - should move to next page if not enough room
                H2 { "STICKY HEADER TEST" }
                    .css.pageBreakAfter(.avoid)

                // Following content that must stay with header
                Paragraph { "This paragraph must stay on the same page as the header." }
            }
        }

        let (pages, _) = PDF.HTML.pages {
            StickyHeaderTest()
        }

        // Find which page has "STICKY HEADER TEST"
        var headerPage: Int?
        var contentPage: Int?

        for (pageIndex, page) in pages.enumerated() {
            for op in page {
                if case .text(let textOp) = op {
                    if textOp.text.contains("STICKY") {
                        headerPage = pageIndex
                        print("Found header on page \(pageIndex + 1) at Y=\(textOp.position.y)")
                    }
                    if textOp.text.contains("must stay") {
                        contentPage = pageIndex
                        print("Found content on page \(pageIndex + 1) at Y=\(textOp.position.y)")
                    }
                }
            }
        }

        // Header and following content must be on the same page
        #expect(headerPage != nil, "Should find the sticky header")
        #expect(contentPage != nil, "Should find the following content")
        #expect(headerPage == contentPage, "Sticky header and following content must be on the same page (header: page \(String(describing: headerPage.map { $0 + 1 })), content: page \(String(describing: contentPage.map { $0 + 1 })))")
    }

    @Test
    func `NDA sticky headers work correctly`() throws {
        // Test just the NDA demo to verify sticky headers work
        let (pages, _) = PDF.HTML.pages {
            NDADemo()
        }

        // Find all ARTICLE headers and their following content
        var articlePositions: [(article: String, page: Int, y: PDF.UserSpace.Unit)] = []

        for (pageIndex, page) in pages.enumerated() {
            for op in page {
                if case .text(let textOp) = op {
                    if textOp.text.contains("ARTICLE") {
                        articlePositions.append((textOp.text, pageIndex, textOp.position.y.value))
                        print("Page \(pageIndex + 1): '\(textOp.text)' at Y=\(textOp.position.y.value)")
                    }
                }
            }
        }

        // Check that no ARTICLE header is orphaned at the very bottom of a page
        // (We consider "near bottom" as Y > 700 for a standard 792pt page with 72pt margins)
        let pageHeight: PDF.UserSpace.Unit = 792.0 - 72.0 - 72.0  // 648 points usable
        let bottomThreshold: PDF.UserSpace.Unit = 72.0 + pageHeight - 50.0  // Last 50 points of usable area

        for pos in articlePositions {
            let isNearBottom = pos.y > bottomThreshold
            if isNearBottom {
                // Check if there's content after this header on the same page
                let hasContentAfter = pages[pos.page].contains { op in
                    if case .text(let textOp) = op {
                        return textOp.position.y.value > pos.y && !textOp.text.contains("ARTICLE")
                    }
                    return false
                }
                print("Header '\(pos.article)' at Y=\(pos.y) near bottom, hasContentAfter=\(hasContentAfter)")
                #expect(hasContentAfter, "ARTICLE header near bottom should have content after it on same page")
            }
        }
    }

    @Test
    func `document showing all elements and properties`() throws {
        struct ComplexView: HTML.View {
            var body: some HTML.View {
                TextStylingDemo()
                LinksDemo()
                BlockElementsDemo()
                ListsDemo()
                HeadingsDemo()
                TableDemo()
                DescriptionListDemo()
                SemanticDemo()
                FigureDemo()
                NestedListDemo()
                InlineStyleDemo()
                Paragraph { Emphasis { "End of demo." } }
                NDADemo()
            }
        }

        let doc = PDF.Document(
            info: .init(
                title: "All Elements Demo",
                author: "Test Suite"
            )
        ) {
            ComplexView()
        }

        let bytes = [UInt8](doc)

        // Write to /tmp for visual inspection
        let url = URL(fileURLWithPath: "/tmp/html-to-pdf-refactor-test.pdf")
        try Data(bytes).write(to: url)
        print("PDF written to: \(url.path)")

        // Basic sanity checks
        #expect(doc.pages.count >= 1)
        #expect(bytes.count > 1000, "Complex document should have substantial content")
    }
}
//
//// MARK: - Demo Helper Views

private struct TextStylingDemo: HTML.View {
    var body: some HTML.View {
        H1 { "All HTML Elements Demo" }
        H2 { "1. Text Styling" }
        Paragraph {
            "Normal, "
            StrongImportance { "bold" }
            ", "
            Emphasis { "italic" }
            ", "
            Code { "code" }
            "."
        }
        Paragraph {
            Mark { "highlighted" }
            ", "
            Strikethrough { "strikethrough" }
            ", "
            UnarticulatedAnnotation { "underline" }
            "."
        }
        Paragraph {
            "H"
            Subscript { "2" }
            "O, E=mc"
            Superscript { "2" }
            "."
        }
        Paragraph {
            "Read "
            Cite { "1984" }
            " by George Orwell."
        }
        Paragraph {
            "Press "
            KeyboardInput { "Ctrl+C" }
            " to copy."
        }
        Paragraph {
            "Output: "
            Samp { "Hello, World!" }
        }
        Paragraph {
            "Let "
            Variable { "x" }
            " = 5."
        }
        Paragraph {
            "The "
            Definition { "DOM" }
            " is the Document Object Model."
        }
        Paragraph {
            "The "
            Abbreviation { "HTML" }
            " specification."
        }
        Paragraph {
            "She said, "
            InlineQuotation { "Hello!" }
        }
        Paragraph {
            "Line 1"
            BR()
            "Line 2 (after BR)"
        }
        Paragraph {
            "Meeting at "
            Time { "2024-01-15" }
            "."
        }
    }
}

private struct LinksDemo: HTML.View {
    var body: some HTML.View {
        H2 { "2. Links" }
        Paragraph {
            "Visit "
            Anchor(href: "https://example.com") { "Example Website" }
            " for more info."
        }
        Paragraph {
            "Contact: "
            Anchor(href: "mailto:test@example.com") { "test@example.com" }
        }
    }
}

private struct BlockElementsDemo: HTML.View {
    var body: some HTML.View {
        H2 { "3. Block Elements" }
        BlockQuote {
            Paragraph { "This is a block quotation." }
        }
        PreformattedText {
            "func hello() {\n    print(\"Hello\")\n}"
        }
        ThematicBreak()
    }
}

private struct ListsDemo: HTML.View {
    var body: some HTML.View {
        H2 { "4. Lists" }
        UnorderedList {
            ListItem { "Bullet 1" }
            ListItem { "Bullet 2" }
        }
        OrderedList {
            ListItem { "Number 1" }
            ListItem { "Number 2" }
        }
    }
}

private struct HeadingsDemo: HTML.View {
    var body: some HTML.View {
        H2 { "5. Headings" }
        H1 { "H1" }
        H2 { "H2" }
        H3 { "H3" }
        H4 { "H4" }
        H5 { "H5" }
        H6 { "H6" }
    }
}

private struct TableDemo: HTML.View {
    var body: some HTML.View {
        Table {
            Caption { "Sample Data Table" }
            TableHead {
                TableRow {
                    TableHeader { "Name" }
                    TableHeader { "Age" }
                    TableHeader { "City" }
                }
            }
            TableBody {
                TableRow {
                    TableDataCell { "Alice" }
                    TableDataCell { "30" }
                    TableDataCell { "New York" }
                }
                TableRow {
                    TableDataCell { "Bob" }
                    TableDataCell { "25" }
                    TableDataCell { "Los Angeles" }
                }
            }
        }
    }
}

private struct DescriptionListDemo: HTML.View {
    var body: some HTML.View {
        DescriptionList {
            DescriptionTerm { "HTML" }
            DescriptionDetails { "HyperText Markup Language" }
            DescriptionTerm { "CSS" }
            DescriptionDetails { "Cascading Style Sheets" }
            DescriptionTerm { "PDF" }
            DescriptionDetails { "Portable Document Format" }
        }
    }
}

private struct SemanticDemo: HTML.View {
    var body: some HTML.View {
        Article {
            Header {
                H3 { "Article Title" }
            }
            Section {
                Paragraph { "Main content of the article." }
            }
            Footer {
                Paragraph { Small { "Author: Test Suite" } }
            }
        }
    }
}

private struct FigureDemo: HTML.View {
    var body: some HTML.View {
        Figure {
            Paragraph { "[Image placeholder]" }
            FigureCaption { "Figure 1: Sample figure." }
        }
    }
}

private struct NestedListDemo: HTML.View {
    var body: some HTML.View {
        UnorderedList {
            ListItem { "Item 1" }
            ListItem {
                "Item 2 with nested:"
                UnorderedList {
                    ListItem { "Nested 2.1" }
                    ListItem { "Nested 2.2" }
                }
            }
            ListItem { "Item 3" }
        }
    }
}

private struct NDADemo: HTML.View {
    var body: some HTML.View {
        // Page break before NDA section
        ContentDivision {
            H1 { "NON-DISCLOSURE AGREEMENT" }
                .css.textAlign(.center)
        }
        .css.pageBreakBefore(.always)

        Paragraph {
            StrongImportance { "THIS NON-DISCLOSURE AGREEMENT" }
            " (the \"Agreement\") is entered into as of "
            ContentSpan { "[DATE]" }
                .css.textDecoration(.underline)
            " by and between:"
        }

        // Parties
        Paragraph {
            StrongImportance { "DISCLOSING PARTY:" }
            BR()
            "[Company Name], a [State] corporation, with its principal place of business at [Address] (\"Discloser\")"
        }

        Paragraph {
            StrongImportance { "RECEIVING PARTY:" }
            BR()
            "[Recipient Name], an individual/entity located at [Address] (\"Recipient\")"
        }

        Paragraph {
            "(Discloser and Recipient are collectively referred to as the \"Parties\")"
        }

        // Recitals - sticky header (won't be orphaned at bottom of page)
        H2 { "RECITALS" }
            .css.pageBreakAfter(.avoid)

        Paragraph {
            StrongImportance { "WHEREAS" }
            ", the Discloser possesses certain confidential and proprietary information relating to [describe business/technology/project] (the \"Purpose\"); and"
        }

        Paragraph {
            StrongImportance { "WHEREAS" }
            ", the Recipient desires to receive certain Confidential Information for the Purpose; and"
        }

        Paragraph {
            StrongImportance { "NOW, THEREFORE" }
            ", in consideration of the mutual covenants and agreements set forth herein, and for other good and valuable consideration, the receipt and sufficiency of which are hereby acknowledged, the Parties agree as follows:"
        }

        // Article 1 - sticky header
        H2 { "ARTICLE 1: DEFINITIONS" }
            .css.pageBreakAfter(.avoid)

        Paragraph {
            StrongImportance { "1.1 \"Confidential Information\"" }
            " means any and all information or data, whether oral, written, electronic, or visual, that is disclosed by the Discloser to the Recipient, including but not limited to:"
        }

        OrderedList {
            ListItem { "Trade secrets, inventions, ideas, processes, formulas, source code, and software;" }
            ListItem { "Business plans, financial information, and customer lists;" }
            ListItem { "Technical data, know-how, and research findings;" }
            ListItem { "Any other information designated as \"Confidential\" at the time of disclosure." }
        }

        // Article 2 - sticky header
        H2 { "ARTICLE 2: OBLIGATIONS OF RECIPIENT" }
            .css.pageBreakAfter(.avoid)

        Paragraph {
            StrongImportance { "2.1 Non-Disclosure." }
            " The Recipient agrees to hold and maintain the Confidential Information in strict confidence and shall not, without the prior written approval of the Discloser:"
        }

        OrderedList {
            ListItem { "Disclose any Confidential Information to any third parties;" }
            ListItem { "Use the Confidential Information for any purpose other than the Purpose;" }
            ListItem { "Copy or reproduce the Confidential Information except as necessary for the Purpose." }
        }

        Paragraph {
            StrongImportance { "2.2 Standard of Care." }
            " The Recipient shall protect the Confidential Information using the same degree of care it uses to protect its own confidential information, but in no event less than reasonable care."
        }

        // Article 3 - sticky header
        H2 { "ARTICLE 3: TERM AND TERMINATION" }
            .css.pageBreakAfter(.avoid)

        Paragraph {
            StrongImportance { "3.1 Term." }
            " This Agreement shall remain in effect for a period of "
            ContentSpan { "[NUMBER]" }
                .css.textDecoration(.underline)
            " years from the Effective Date, unless earlier terminated in accordance with this Agreement."
        }

        Paragraph {
            StrongImportance { "3.2 Survival." }
            " The confidentiality obligations under this Agreement shall survive termination and continue for a period of "
            ContentSpan { "[NUMBER]" }
                .css.textDecoration(.underline)
            " years following termination."
        }

        // Article 4 - sticky header
        H2 { "ARTICLE 4: GENERAL PROVISIONS" }
            .css.pageBreakAfter(.avoid)

        Paragraph {
            StrongImportance { "4.1 Governing Law." }
            " This Agreement shall be governed by and construed in accordance with the laws of the State of "
            ContentSpan { "[STATE]" }
                .css.textDecoration(.underline)
            ", without regard to its conflict of laws principles."
        }

        Paragraph {
            StrongImportance { "4.2 Entire Agreement." }
            " This Agreement constitutes the entire agreement between the Parties with respect to the subject matter hereof and supersedes all prior negotiations, representations, or agreements relating thereto."
        }

        Paragraph {
            StrongImportance { "4.3 Amendments." }
            " This Agreement may not be amended or modified except by a written instrument signed by both Parties."
        }

        // Signature block - sticky header
        H2 { "SIGNATURES" }
            .css.pageBreakAfter(.avoid)

        Paragraph {
            StrongImportance { "IN WITNESS WHEREOF" }
            ", the Parties have executed this Non-Disclosure Agreement as of the date first written above."
        }

        // Signature lines
        Paragraph {
            StrongImportance { "DISCLOSER:" }
        }
        Paragraph {
            BR()
            "________________________________"
            BR()
            "Name: [Authorized Representative]"
            BR()
            "Title: [Title]"
            BR()
            "Date: _______________"
        }

        Paragraph {
            StrongImportance { "RECIPIENT:" }
        }
        Paragraph {
            BR()
            "________________________________"
            BR()
            "Name: [Recipient Name]"
            BR()
            "Title: [Title]"
            BR()
            "Date: _______________"
        }
    }
}

private struct InlineStyleDemo: HTML.View {
    var body: some HTML.View {
        H2 { "10. CSS Styling" }
        Paragraph {
            "Color: "
            ContentSpan { "red" }
                .css.color(.red)
            ", "
            ContentSpan { "blue" }
                .css.color(.blue)
            ", "
            ContentSpan { "green" }
                .css.color(.green)
            "."
        }
        Paragraph {
            "Background: "
            ContentSpan { " highlighted " }
                .css.backgroundColor(.yellow)
            " text."
        }
        Paragraph {
            "Font weight: "
            ContentSpan { "bold" }
                .css.fontWeight(.bold)
            ", "
            ContentSpan { "normal" }
                .css.fontWeight(.normal)
            "."
        }
        Paragraph {
            "Font style: "
            ContentSpan { "italic" }
                .css.fontStyle(.italic)
            ", "
            ContentSpan { "normal" }
                .css.fontStyle(.normal)
            "."
        }
        Paragraph {
            "Font size: "
            ContentSpan { "small" }
                .css.fontSize(.absoluteSize(.small))
            ", "
            ContentSpan { "large" }
                .css.fontSize(.absoluteSize(.large))
            ", "
            ContentSpan { "x-large" }
                .css.fontSize(.absoluteSize(.xLarge))
            "."
        }
        ContentDivision {
            Paragraph { "Content in a div." }
        }
    }
}
