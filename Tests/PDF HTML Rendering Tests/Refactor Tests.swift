// Refactor Tests.swift
// Tests for the two-phase HTML → PDF transformation

import CSS
import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

@Suite
struct `PDF.HTML.View Tests` {

    // MARK: - Basic Transformation

    @Test
    func `String transforms to PDF content`() {
        let html = "Hello, World!"
        let pages = PDF.HTML.pages {
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

        let pages = PDF.HTML.pages(configuration: .init(), content: TestView.init)

        // Should have at least one page with content
        #expect(pages.count >= 1)
        #expect(!pages[0].contents.isEmpty)
    }

    @Test
    func `Heading transforms`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                H1 { "Big Heading" }
            }
        }

        let pages = PDF.HTML.pages(configuration: .init(), content: TestView.init)
        #expect(pages.count >= 1)
        #expect(!pages[0].contents.isEmpty)
    }

    // MARK: - Inline Flow

    @Test
    func `Inline elements render together`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    "Normal "
                    StrongImportance { "bold" }
                    " normal"
                }
            }
        }

        let pages = PDF.HTML.pages(configuration: .init(), content: TestView.init)
        #expect(pages.count >= 1)

        // Check content stream contains text
        let contentData = pages[0].contents.first?.data ?? []
        let contentString = String(decoding: contentData, as: UTF8.self)
        #expect(contentString.contains("Normal"))
        #expect(contentString.contains("bold"))
    }

    //    @Test
    //    func `Bold applies font`() {
    //        struct TestView: HTML.View {
    //            var body: some HTML.View {
    //                Paragraph {
    //                    StrongImportance { "Bold text" }
    //                }
    //            }
    //        }
    //
    //        let pages = PDF.HTML.pages(configuration: .init(), content: TestView.init)
    //        #expect(pages.count >= 1)
    //
    //        // Check that Helvetica-Bold font is used
    //        let fonts = pages[0].resources.fonts
    //        let hasBoldFont = fonts.values.contains { font in
    //            font.baseFontName.contains("Bold")
    //        }
    //        #expect(hasBoldFont, "Should use bold font for <strong>")
    //    }
    //
    //    @Test
    //    func `Italic applies font`() {
    //        struct TestView: HTML.View {
    //            var body: some HTML.View {
    //                Paragraph {
    //                    Emphasis { "Italic text" }
    //                }
    //            }
    //        }
    //
    //        let pages = PDF.HTML.pages {
    //            TestView()
    //        }
    //
    //        #expect(pages.count >= 1)
    //
    //        // Check that italic/oblique font is used
    //        let fonts = pages[0].resources.fonts
    //        let hasItalicFont = fonts.values.contains { font in
    //            font.baseFontName.contains("Oblique") || font.baseFontName.contains("Italic")
    //        }
    //        #expect(hasItalicFont, "Should use italic font for <em>")
    //    }
    //
    //    @Test
    //    func `Bold + Italic combines correctly`() {
    //        struct TestView: HTML.View {
    //            var body: some HTML.View {
    //                Paragraph {
    //                    StrongImportance {
    //                        Emphasis { "Bold italic" }
    //                    }
    //                }
    //            }
    //        }
    //
    //        let pages = PDF.HTML.pages(configuration: .init(), content: TestView.init)
    //        #expect(pages.count >= 1)
    //
    //        // Check that bold-oblique font is used
    //        let fonts = pages[0].resources.fonts
    //        let hasBoldItalicFont = fonts.values.contains { font in
    //            font.baseFontName.contains("BoldOblique") || font.baseFontName.contains("BoldItalic")
    //        }
    //        #expect(hasBoldItalicFont, "Should use bold-italic font for nested <strong><em>")
    //    }

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
        #expect(config.headingSize(level: 3) == config.defaultFontSize * 1.17)
    }

    @Test
    func `Configuration affects content dimensions`() {
        let config = PDF.HTML.Configuration(
            paperSize: .a4,
            margins: .init(top: 72, leading: 72, bottom: 72, trailing: 72)
        )

        #expect(config.content.width == PDF.UserSpace.Rectangle.a4.width - 144)
        #expect(config.content.height == PDF.UserSpace.Rectangle.a4.height - 144)
    }
}

// MARK: - Sticky Header Tests

@Suite
struct `Sticky Header Tests` {

    @Test
    func `Basic sticky header document renders`() {
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

        let pages = PDF.HTML.pages { TestView() }

        // Should have at least one page and render without crash
        #expect(pages.count >= 1)

        // Check that both header and content text exist in the PDF
        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("STICKY_HEADER"))
        #expect(contentString.contains("FOLLOWING_CONTENT"))
    }

    @Test
    func `Sticky header at document end renders`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Some content" }

                // Sticky header with no following content
                H2 { "ORPHAN_HEADER" }
                    .css.pageBreakAfter(.avoid)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Header should still be rendered
        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("ORPHAN_HEADER"), "Orphan sticky header should be rendered")
    }
}

// MARK: - Comprehensive Test

@Suite
struct `Comprehensive PDF.HTML.View Tests` {

    @Test
    func `document showing all elements and properties with outline`() throws {
        let doc = PDF.Document(
            info: .init(
                title: "All Elements Demo",
                author: "Test Suite"
            ),
            generateOutline: true
        ) {
            ComplexView()
        }

        let bytes = [UInt8](doc)

        // Write to the temp directory for visual inspection
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "html-to-pdf-refactor-test.pdf"
        )
        try Data(bytes).write(to: url)
        print("PDF written to: \(url.path)")

        // Basic sanity checks
        #expect(doc.pages.count >= 1)
        #expect(bytes.count > 1000, "Complex document should have substantial content")

        // Outline should be generated from headings
        #expect(doc.outline != nil, "Document should have outline/bookmarks")
        if let outline = doc.outline {
            #expect(!outline.items.isEmpty, "Outline should have items from H1-H6 headings")
        }
    }

    @Test
    func `document with nested collapsible outline structure`() throws {
        let doc = PDF.Document(
            info: .init(
                title: "Technical Specification",
                author: "Test Suite"
            ),
            generateOutline: true
        ) {
            TechnicalSpecificationView()
        }

        let bytes = [UInt8](doc)

        // Write to the temp directory for visual inspection
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "nested-outline-test.pdf"
        )
        try Data(bytes).write(to: url)
        print("PDF with nested outline written to: \(url.path)")

        // Basic sanity checks
        #expect(doc.pages.count >= 1)

        // Verify nested outline structure
        #expect(doc.outline != nil, "Document should have outline/bookmarks")

        if let outline = doc.outline {
            // Print outline structure for debugging
            print("Outline structure:")
            printOutline(outline.items, indent: 0)

            // Verify we have top-level items
            #expect(!outline.items.isEmpty, "Outline should have top-level items")
        }
    }
}

/// Helper to print outline structure for debugging
private func printOutline(_ items: [ISO_32000.Outline.Item], indent: Int) {
    let prefix = String(repeating: "  ", count: indent)
    for item in items {
        print("\(prefix)- \(item.title)")
        if !item.children.isEmpty {
            printOutline(item.children, indent: indent + 1)
        }
    }
}

/// A technical specification document with nested heading structure
/// Similar to ISO standards with numbered sections
private struct TechnicalSpecificationView: HTML.View {
    var body: some HTML.View {
        // Front matter
        H1 { "Technical Specification XYZ-2024" }
            .css.textAlign(.center)
        Paragraph { "A comprehensive guide to the XYZ standard." }

        // Section 1
        H1 { "1 Scope" }
        Paragraph { "This document specifies the requirements for XYZ systems." }

        // Section 2
        H1 { "2 Normative references" }
        Paragraph { "The following documents are referred to in the text." }

        // Section 3
        H1 { "3 Terms and definitions" }
        Paragraph { "For the purposes of this document, the following terms apply." }

        // Section 4 with subsections
        H1 { "4 Notation" }
        Paragraph { "This section describes the notation used throughout the document." }

        H2 { "4.1 General" }
        Paragraph { "General notation conventions are described here." }

        H2 { "4.2 Established notations" }
        Paragraph { "Industry-standard notations that are adopted." }

        H2 { "4.3 Special symbols" }
        Paragraph { "Special symbols used in this specification." }

        H3 { "4.3.1 Mathematical symbols" }
        Paragraph { "Symbols used for mathematical expressions." }

        H3 { "4.3.2 Logical symbols" }
        Paragraph { "Symbols used for logical operations." }

        // Section 5
        H1 { "5 Version designations" }
        Paragraph { "How versions are designated in this standard." }

        // Section 6 with deep nesting
        H1 { "6 Conformance" }
        Paragraph { "Requirements for conformance to this specification." }

        H2 { "6.1 Conformance levels" }
        Paragraph { "Different levels of conformance are defined." }

        H3 { "6.1.1 Basic conformance" }
        Paragraph { "Minimum requirements for basic conformance." }

        H3 { "6.1.2 Full conformance" }
        Paragraph { "Requirements for full conformance." }

        H4 { "6.1.2.1 Mandatory features" }
        Paragraph { "Features that must be implemented." }

        H4 { "6.1.2.2 Optional features" }
        Paragraph { "Features that may optionally be implemented." }

        H2 { "6.2 Conformance testing" }
        Paragraph { "How conformance is verified." }

        // Section 7
        H1 { "7 Syntax" }
        Paragraph { "The syntax of the XYZ language." }

        H2 { "7.1 Lexical elements" }
        Paragraph { "Basic lexical elements of the language." }

        H2 { "7.2 Expressions" }
        Paragraph { "How expressions are formed." }

        H2 { "7.3 Statements" }
        Paragraph { "Statement syntax and semantics." }

        // Section 8
        H1 { "8 Graphics" }
        Paragraph { "Graphics capabilities of the system." }

        H2 { "8.1 Coordinate systems" }
        Paragraph { "How coordinates are specified." }

        H2 { "8.2 Transformations" }
        Paragraph { "Geometric transformations supported." }

        // Section 9 with multiple levels
        H1 { "9 Text" }
        Paragraph { "Text handling capabilities." }

        H2 { "9.1 General" }
        Paragraph { "Overview of text handling." }

        H2 { "9.2 Organisation and use of fonts" }
        Paragraph { "How fonts are organized and used." }

        H3 { "9.2.1 Font types" }
        Paragraph { "Different types of fonts supported." }

        H3 { "9.2.2 Font embedding" }
        Paragraph { "How fonts are embedded in documents." }

        H2 { "9.3 Text state parameters and operators" }
        Paragraph { "Parameters that control text rendering." }

        H2 { "9.4 Text objects" }
        Paragraph { "How text objects are defined." }

        H2 { "9.5 Introduction to font data structures" }
        Paragraph { "Overview of font data structures." }

        H2 { "9.6 Simple fonts" }
        Paragraph { "Simple font types and their properties." }

        H3 { "9.6.1 Type 1 fonts" }
        Paragraph { "Adobe Type 1 font format." }

        H3 { "9.6.2 TrueType fonts" }
        Paragraph { "TrueType font format." }

        H2 { "9.7 Composite fonts" }
        Paragraph { "Composite font architecture." }

        H2 { "9.8 Font descriptors" }
        Paragraph { "Metadata about fonts." }

        // Annex
        H1 { "Annex A (normative) Implementation notes" }
        Paragraph { "Notes for implementers of this specification." }

        H1 { "Annex B (informative) Examples" }
        Paragraph { "Example implementations and use cases." }

        H2 { "B.1 Basic example" }
        Paragraph { "A simple example demonstrating core features." }

        H2 { "B.2 Advanced example" }
        Paragraph { "A complex example showing advanced features." }
    }
}

// import HtmlToPdf
// @Suite
// struct `Comprehensive PDF.HTML.View Tests 2 htmltopdf` {
//
//    @Test
//    func `document showing all elements and properties`() async throws {
//        @Dependency(\.pdf) var pdf
//
//        try await withDependencies {
//            $0.pdf.render.configuration.paginationMode = .paginated
//        } operation: {
//            _ = try await pdf.render(
//                html: ComplexView(),
//                to: FileManager.default.temporaryDirectory
//                    .appendingPathComponent("html-to-pdf-refactor-test-webkit.pdf")
//            )
//        }
//    }
// }

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
        //        ThematicBreak.init()
    }
}

private struct ListsDemo: HTML.View {
    var body: some HTML.View {
        H2 { "4. Lists" }
            .css.pageBreakAfter(.avoid)

        // Simple unordered list
        H3 { "4.1 Simple Unordered List" }
            .css.pageBreakAfter(.avoid)

        UnorderedList {
            ListItem { "First bullet point" }
            ListItem { "Second bullet point" }
            ListItem { "Third bullet point" }
        }

        // Simple ordered list
        H3 { "4.2 Simple Ordered List" }
        OrderedList {
            ListItem { "First numbered item" }
            ListItem { "Second numbered item" }
            ListItem { "Third numbered item" }
        }

        // List with longer content that wraps
        H3 { "4.3 List Items with Wrapping Text" }
        OrderedList {
            ListItem {
                "This is a longer list item that should wrap to multiple lines to test how the list marker aligns with multi-line content in an ordered list."
            }
            ListItem {
                "Another lengthy item with sufficient text to cause line wrapping and verify proper indentation is maintained throughout."
            }
            ListItem { "Short item." }
        }

        // List with inline formatting
        H3 { "4.4 List Items with Inline Formatting" }
        UnorderedList {
            ListItem {
                StrongImportance { "Bold text" }
                " followed by normal text"
            }
            ListItem {
                "Normal text with "
                Emphasis { "italic" }
                " in the middle"
            }
            ListItem {
                Code { "inline code" }
                " mixed with regular text"
            }
            ListItem {
                "Link: "
                Anchor(href: "https://example.com") { "Example Website" }
            }
        }

        // Nested lists
        H3 { "4.5 Nested Lists" }
        UnorderedList {
            ListItem { "Level 1 - Item A" }
            ListItem {
                "Level 1 - Item B with nested list:"
                UnorderedList {
                    ListItem { "Level 2 - Nested item 1" }
                    ListItem { "Level 2 - Nested item 2" }
                    ListItem {
                        "Level 2 - Item with deeper nesting:"
                        UnorderedList {
                            ListItem { "Level 3 - Deep nested item" }
                        }
                    }
                }
            }
            ListItem { "Level 1 - Item C" }
        }

        // Mixed nested lists (ordered inside unordered)
        H3 { "4.6 Mixed Nested Lists" }
        OrderedList {
            ListItem { "First main item" }
            ListItem {
                "Second main item with sub-points:"
                UnorderedList {
                    ListItem { "Sub-point A" }
                    ListItem { "Sub-point B" }
                    ListItem { "Sub-point C" }
                }
            }
            ListItem {
                "Third main item with numbered sub-items:"
                OrderedList {
                    ListItem { "Sub-item 1" }
                    ListItem { "Sub-item 2" }
                }
            }
        }

        // Many items to test numbering
        H3 { "4.7 List with Many Items" }
        OrderedList {
            ListItem { "Item one" }
            ListItem { "Item two" }
            ListItem { "Item three" }
            ListItem { "Item four" }
            ListItem { "Item five" }
            ListItem { "Item six" }
            ListItem { "Item seven" }
            ListItem { "Item eight" }
            ListItem { "Item nine" }
            ListItem { "Item ten" }
            ListItem { "Item eleven" }
            ListItem { "Item twelve" }
        }

        // List after paragraph (spacing test)
        H3 { "4.8 List Spacing" }
        Paragraph {
            "This paragraph comes before a list. There should be appropriate spacing between this text and the list below."
        }
        UnorderedList {
            ListItem { "First item after paragraph" }
            ListItem { "Second item" }
        }
        Paragraph {
            "This paragraph comes after the list. Spacing should also be appropriate here."
        }

        // Empty and minimal lists
        H3 { "4.9 Single Item Lists" }
        UnorderedList {
            ListItem { "Only item in unordered list" }
        }
        OrderedList {
            ListItem { "Only item in ordered list" }
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
        H2 { "6. Tables" }
            .css.pageBreakAfter(.avoid)

        // Simple table
        H3 { "6.1 Simple Data Table" }
            .css.pageBreakAfter(.avoid)

        Table {
            Caption { "Employee Directory" }
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
                TableRow {
                    TableDataCell { "Charlie" }
                    TableDataCell { "35" }
                    TableDataCell { "Chicago" }
                }
                TableRow {
                    TableDataCell { "Diana" }
                    TableDataCell { "28" }
                    TableDataCell { "Houston" }
                }
            }
        }

        // Table with more columns
        H3 { "6.2 Product Inventory" }
            .css.pageBreakAfter(.avoid)

        Table {
            TableHead {
                TableRow {
                    TableHeader { "SKU" }
                    TableHeader { "Product Name" }
                    TableHeader { "Category" }
                    TableHeader { "Price" }
                    TableHeader { "Stock" }
                }
            }
            TableBody {
                TableRow {
                    TableDataCell { "A001" }
                    TableDataCell { "Wireless Mouse" }
                    TableDataCell { "Electronics" }
                    TableDataCell { "$29.99" }
                    TableDataCell { "150" }
                }
                TableRow {
                    TableDataCell { "A002" }
                    TableDataCell { "USB-C Hub" }
                    TableDataCell { "Electronics" }
                    TableDataCell { "$49.99" }
                    TableDataCell { "75" }
                }
                TableRow {
                    TableDataCell { "B001" }
                    TableDataCell { "Ergonomic Chair" }
                    TableDataCell { "Furniture" }
                    TableDataCell { "$299.00" }
                    TableDataCell { "25" }
                }
                TableRow {
                    TableDataCell { "B002" }
                    TableDataCell { "Standing Desk" }
                    TableDataCell { "Furniture" }
                    TableDataCell { "$450.00" }
                    TableDataCell { "12" }
                }
                TableRow {
                    TableDataCell { "C001" }
                    TableDataCell { "Notebook Set" }
                    TableDataCell { "Office Supplies" }
                    TableDataCell { "$12.99" }
                    TableDataCell { "500" }
                }
            }
        }

        // Table with inline formatting
        H3 { "6.3 Table with Formatted Content" }
            .css.pageBreakAfter(.avoid)

        Table {
            TableHead {
                TableRow {
                    TableHeader { "Feature" }
                    TableHeader { "Status" }
                    TableHeader { "Notes" }
                }
            }
            TableBody {
                TableRow {
                    TableDataCell {
                        StrongImportance { "Authentication" }
                    }
                    TableDataCell { "Complete" }
                    TableDataCell {
                        "Supports "
                        Code { "OAuth 2.0" }
                        " and "
                        Code { "JWT" }
                    }
                }
                TableRow {
                    TableDataCell {
                        StrongImportance { "API Gateway" }
                    }
                    TableDataCell { "In Progress" }
                    TableDataCell {
                        Emphasis { "Expected Q2 2025" }
                    }
                }
                TableRow {
                    TableDataCell {
                        StrongImportance { "Dashboard" }
                    }
                    TableDataCell { "Planned" }
                    TableDataCell { "See roadmap for details" }
                }
            }
        }

        // Table with footer
        H3 { "6.4 Financial Summary with Footer" }
            .css.pageBreakAfter(.avoid)

        Table {
            TableHead {
                TableRow {
                    TableHeader { "Quarter" }
                    TableHeader { "Revenue" }
                    TableHeader { "Expenses" }
                    TableHeader { "Profit" }
                }
            }
            TableBody {
                TableRow {
                    TableDataCell { "Q1 2024" }
                    TableDataCell { "$125,000" }
                    TableDataCell { "$95,000" }
                    TableDataCell { "$30,000" }
                }
                TableRow {
                    TableDataCell { "Q2 2024" }
                    TableDataCell { "$142,000" }
                    TableDataCell { "$98,000" }
                    TableDataCell { "$44,000" }
                }
                TableRow {
                    TableDataCell { "Q3 2024" }
                    TableDataCell { "$158,000" }
                    TableDataCell { "$102,000" }
                    TableDataCell { "$56,000" }
                }
                TableRow {
                    TableDataCell { "Q4 2024" }
                    TableDataCell { "$175,000" }
                    TableDataCell { "$110,000" }
                    TableDataCell { "$65,000" }
                }
            }
            TableFoot {
                TableRow {
                    TableHeader { "Total" }
                    TableDataCell { "$600,000" }
                    TableDataCell { "$405,000" }
                    TableDataCell {
                        StrongImportance { "$195,000" }
                    }
                }
            }
        }

        // Two-column simple table
        H3 { "6.5 Key-Value Table" }
            .css.pageBreakAfter(.avoid)

        Table {
            TableBody {
                TableRow {
                    TableHeader { "Version" }
                    TableDataCell { "2.4.1" }
                }
                TableRow {
                    TableHeader { "Release Date" }
                    TableDataCell { "December 10, 2024" }
                }
                TableRow {
                    TableHeader { "License" }
                    TableDataCell { "MIT" }
                }
                TableRow {
                    TableHeader { "Author" }
                    TableDataCell { "Coen ten Thije Boonkkamp" }
                }
                TableRow {
                    TableHeader { "Repository" }
                    TableDataCell { "github.com/coenttb/swift-pdf-html-rendering" }
                }
            }
        }

        // MARK: - 6.6 Colspan/Rowspan Table

        H3 { "6.6 Colspan/Rowspan Table" }
            .css.pageBreakAfter(.avoid)

        Table {
            TableHead {
                TableRow {
                    TableHeader { "Category" }
                    TableHeader(colspan: 2) { "Details" }
                    TableHeader { "Status" }
                }
            }
            TableBody {
                TableRow {
                    TableHeader(rowspan: 2) { "Rendering" }
                    TableDataCell { "Tables" }
                    TableDataCell { "Full support" }
                    TableDataCell { "✓" }
                }
                TableRow {
                    // First column skipped due to rowspan
                    TableDataCell { "Lists" }
                    TableDataCell { "Full support" }
                    TableDataCell { "✓" }
                }
                TableRow {
                    TableHeader(rowspan: 3) { "Typography" }
                    TableDataCell { "Headings" }
                    TableDataCell { "H1-H6" }
                    TableDataCell { "✓" }
                }
                TableRow {
                    TableDataCell { "Inline styles" }
                    TableDataCell { "Bold, italic, etc." }
                    TableDataCell { "✓" }
                }
                TableRow {
                    TableDataCell { "Links" }
                    TableDataCell { "Clickable URLs" }
                    TableDataCell { "✓" }
                }
                TableRow {
                    TableDataCell(colspan: 3) { "Combined colspan example spanning three columns" }
                    TableDataCell { "OK" }
                }
            }
            TableFoot {
                TableRow {
                    TableDataCell(colspan: 4) { "All features implemented and tested" }
                }
            }
        }

        // MARK: - 6.7 Text Alignment Table

        H3 { "6.7 Text Alignment (CSS)" }
            .css.pageBreakAfter(.avoid)

        Table {
            TableHead {
                TableRow {
                    TableHeader { "Product" }
                    TableHeader { "Quantity" }
                        .css.textAlign(.right)
                    TableHeader { "Price" }
                        .css.textAlign(.right)
                    TableHeader { "Total" }
                        .css.textAlign(.right)
                }
            }
            TableBody {
                TableRow {
                    TableDataCell { "Widget A" }
                    TableDataCell { "10" }
                        .css.textAlign(.right)
                    TableDataCell { "$5.00" }
                        .css.textAlign(.right)
                    TableDataCell { "$50.00" }
                        .css.textAlign(.right)
                }
                TableRow {
                    TableDataCell { "Widget B" }
                    TableDataCell { "25" }
                        .css.textAlign(.right)
                    TableDataCell { "$3.50" }
                        .css.textAlign(.right)
                    TableDataCell { "$87.50" }
                        .css.textAlign(.right)
                }
                TableRow {
                    TableDataCell { "Service Fee" }
                    TableDataCell { "—" }
                        .css.textAlign(.center)
                    TableDataCell { "—" }
                        .css.textAlign(.center)
                    TableDataCell { "$15.00" }
                        .css.textAlign(.right)
                }
            }
            TableFoot {
                TableRow {
                    TableHeader(colspan: 3) { "Grand Total" }
                        .css.textAlign(.right)
                    TableDataCell { "$152.50" }
                        .css.textAlign(.right)
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
            ListItem {
                "Trade secrets, inventions, ideas, processes, formulas, source code, and software;"
            }
            ListItem { "Business plans, financial information, and customer lists;" }
            ListItem { "Technical data, know-how, and research findings;" }
            ListItem {
                "Any other information designated as \"Confidential\" at the time of disclosure."
            }
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
            ListItem {
                "Copy or reproduce the Confidential Information except as necessary for the Purpose."
            }
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
        .css.pageBreakAfter(.avoid)

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
        .css.pageBreakAfter(.avoid)

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
