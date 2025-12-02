// HTML Tests.swift

import Foundation
import Testing
@testable import HTML_PDF_Rendering
import PDF_Rendering
import PDF_Standard
import HTML_Rendering
import CSS

@Suite
struct `HTML PDF.Document Tests` {

    // MARK: - Builder Syntax

    @Test
    func `Creates document with HTML builder`() {
        let document = PDF.Document(title: "Test") {
            ContentDivision {
                "Hello, World!"
            }
        }

        #expect(document.pages.count == 1)
        #expect(document.info?.title == "Test")
    }

    @Test
    func `Creates document with all metadata`() {
        let document = PDF.Document(
            title: "My Title",
            author: "Test Author",
            subject: "Test Subject",
            keywords: "test, pdf, swift"
        ) {
            Paragraph { "Content" }
        }

        #expect(document.info?.title == "My Title")
        #expect(document.info?.author == "Test Author")
        #expect(document.info?.subject == "Test Subject")
        #expect(document.info?.keywords == "test, pdf, swift")
    }

    @Test
    func `Creates document with custom configuration`() {
        let config = HTML.Configuration(
            paperSize: .letter,
            defaultFontSize: 14
        )

        let document = PDF.Document(configuration: config) {
            ContentDivision { "Content" }
        }

        #expect(document.pages.first?.paperSize == .letter)
    }

    // MARK: - Direct HTML View

    @Test
    func `Creates document from HTML view`() {
        let html = ContentDivision {
            H1 { "Title" }
            Paragraph { "Body text" }
        }

        let document = PDF.Document(html, title: "From View")

        #expect(document.pages.count == 1)
        #expect(document.info?.title == "From View")
    }

    @Test
    func `Creates document from complex HTML`() {
        let html = Article {
            Header {
                H1 { "Article Title" }
            }
            Section {
                Paragraph { "First paragraph." }
                Paragraph { "Second paragraph." }
            }
            Footer {
                "Footer text"
            }
        }

        let document = PDF.Document(html)

        #expect(document.pages.count == 1)
    }

    // MARK: - Page Content

    @Test
    func `Document page has content`() {
        let document = PDF.Document {
            ContentDivision { "Test content" }
        }

        let page = document.pages.first!
        #expect(!page.content.operations.isEmpty)
    }

    @Test
    func `Document uses configuration margins`() {
        let config = HTML.Configuration(
            margins: PDF.EdgeInsets(top: 100, left: 50, bottom: 100, right: 50)
        )

        let document = PDF.Document(configuration: config) {
            ContentDivision { "Content" }
        }

        let page = document.pages.first!
        #expect(page.margins.top == 100)
        #expect(page.margins.left == 50)
    }

    // MARK: - Serialization

    @Test
    func `Document serializes to PDF bytes`() {
        let document = PDF.Document(title: "Serialize Test") {
            H1 { "Hello" }
            Paragraph { "World" }
        }

        let bytes = [UInt8](document)

        #expect(bytes.count > 0)
        #expect(bytes.starts(with: [0x25, 0x50, 0x44, 0x46])) // %PDF
    }
}

// MARK: - HTML Element Integration Tests

@Suite
struct `Inline Text Flow Tests` {

    @Test
    func `Inline text renders on same line`() {
        // This test verifies that inline elements like <strong> and <em>
        // render on the same line as surrounding text
        let document = PDF.Document {
            Paragraph {
                "It supports "
                StrongImportance { "bold" }
                " and "
                Emphasis { "italic" }
                " text."
            }
        }

        let page = document.pages.first!
        let textOps = page.content.operations.compactMap { op -> PDF.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        // With proper inline flow, all text should be on the same Y position
        // (or very close, within floating point tolerance)
        let yPositions = Set(textOps.map { Int($0.position.y) })

        // All text should be on the same line (same Y position)
        #expect(yPositions.count == 1, "Expected all text on same line, got Y positions: \(yPositions)")
    }

    @Test
    func `Write PDF file to disk`() throws {
        // Create a test document with mixed inline content
        struct TestView: HTML.View {
            var body: some HTML.View {
                Article {
                    Header {
                        H1 { "PDF Rendering Test" }
                    }

                    Paragraph {
                        "It supports "
                        StrongImportance { "bold" }
                        " and "
                        Emphasis { "italic" }
                        " text."
                    }

                    H2 { "Features" }

                    UnorderedList {
                        ListItem { "Native Swift implementation" }
                        ListItem { "No external dependencies" }
                        ListItem { "Type-safe HTML to PDF conversion" }
                    }

                    Footer {
                        Paragraph { "Generated on: \(Date())" }
                    }
                }
            }
        }

        let document = PDF.Document(title: "Test Document") {
            TestView()
        }

        let bytes = [UInt8](document)
        let data = Data(bytes)

        let url = URL(fileURLWithPath: "/private/tmp/swift-pdf-test.pdf")
        try data.write(to: url)

        // Verify file was written and has content
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(bytes.count > 500, "PDF should have substantial content")

        // Verify operations were generated
        let page = document.pages.first!
        #expect(!page.content.operations.isEmpty, "PDF should have operations")
    }
}

@Suite
struct `HTML Element Integration Tests` {

    @Test
    func `Heading elements produce bold text`() {
        let document = PDF.Document {
            H1 { "Heading 1" }
            H2 { "Heading 2" }
        }

        let page = document.pages.first!
        let textOps = page.content.operations.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count >= 2)
    }

    @Test
    func `List elements produce multiple text operations`() {
        let document = PDF.Document {
            UnorderedList {
                ListItem { "Item 1" }
                ListItem { "Item 2" }
                ListItem { "Item 3" }
            }
        }

        let page = document.pages.first!
        let textOps = page.content.operations.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count >= 3)
    }

    @Test
    func `Nested formatting produces correct fonts`() {
        let document = PDF.Document {
            Paragraph {
                StrongImportance { "Bold text" }
            }
        }

        let page = document.pages.first!
        let hasBoldText = page.content.operations.contains {
            if case .text(let op) = $0 {
                return op.font == .helveticaBold
            }
            return false
        }

        #expect(hasBoldText)
    }
}

// MARK: - CSS Fluent API Tests

@Suite
struct `CSS Styling Tests` {

    @Test
    func `CSS fluent color styling works`() {
        // This test verifies that .css.color() doesn't crash
        // and produces valid PDF output
        let document = PDF.Document {
            Paragraph {
                "Red text"
            }
            .css
            .color(.red)
        }

        let page = document.pages.first!
        let textOps = page.content.operations.compactMap { op -> PDF.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(!textOps.isEmpty, "Should have text operations")
    }

    @Test
    func `CSS fluent font size styling works`() {
        let document = PDF.Document {
            Paragraph {
                "Large text"
            }
            .css
            .fontSize(.px(24))
        }

        let page = document.pages.first!
        #expect(!page.content.operations.isEmpty)
    }

    @Test
    func `CSS fluent font weight styling works`() {
        let document = PDF.Document {
            Paragraph {
                "Bold text"
            }
            .css
            .fontWeight(.bold)
        }

        let page = document.pages.first!
        #expect(!page.content.operations.isEmpty)
    }

    @Test
    func `CSS chained styling works`() {
        // Chain multiple CSS properties
        let document = PDF.Document {
            Paragraph {
                "Styled text"
            }
            .css
            .color(.blue)
            .fontSize(.px(18))
            .fontWeight(.bold)
        }

        let page = document.pages.first!
        #expect(!page.content.operations.isEmpty)
    }

    @Test
    func `CSS styling on nested elements works`() {
        let document = PDF.Document {
            ContentDivision {
                Paragraph {
                    StrongImportance { "Bold" }
                    " and "
                    Emphasis { "italic" }
                }
            }
            .css
            .color(.green)
        }

        let page = document.pages.first!
        let textOps = page.content.operations.compactMap { op -> PDF.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(textOps.count >= 3, "Should have multiple text operations")
    }
}

// MARK: - Comprehensive Visual Test

@Suite
struct `Comprehensive Visual Tests` {

    @Test("Comprehensive document with all features")
    func comprehensiveDocument() throws {
        // This test creates a PDF showcasing all supported features
        // for visual inspection at /private/tmp/swift-pdf-comprehensive.pdf

        struct ComprehensiveView: HTML.View {
            var body: some HTML.View {
                Article {
                    // MARK: - Title Section
                    Header {
                        H1 { "Swift HTML to PDF Rendering" }
                        Paragraph {
                            "A comprehensive demonstration of all supported HTML elements and CSS styling."
                        }
                    }

                    // MARK: - Heading Hierarchy
                    Section {
                        H2 { "1. Heading Hierarchy" }
                        H1 { "Heading Level 1 (H1)" }
                        H2 { "Heading Level 2 (H2)" }
                        H3 { "Heading Level 3 (H3)" }
                        H4 { "Heading Level 4 (H4)" }
                        H5 { "Heading Level 5 (H5)" }
                        H6 { "Heading Level 6 (H6)" }
                    }

                    // MARK: - Text Formatting
                    Section {
                        H2 { "2. Inline Text Formatting" }
                        Paragraph {
                            "This paragraph demonstrates "
                            StrongImportance { "bold (strong)" }
                            " and "
                            B { "bold (b)" }
                            " text, as well as "
                            Emphasis { "italic (em)" }
                            " and "
                            IdiomaticText { "italic (i)" }
                            " text."
                        }
                        Paragraph {
                            "Additional formatting: "
                            UnarticulatedAnnotation { "underline" }
                            ", "
                            Strikethrough { "strikethrough" }
                            ", "
                            Code { "inline code" }
                            ", "
                            Mark { "highlighted" }
                            ", "
                            Small { "small text" }
                            "."
                        }
                        Paragraph {
                            "Subscript: H"
                            Subscript { "2" }
                            "O and Superscript: E=mc"
                            Superscript { "2" }
                        }
                        Paragraph {
                            "Combined: "
                            StrongImportance {
                                Emphasis { "bold and italic" }
                            }
                            " together."
                        }
                    }

                    // MARK: - Block Elements
                    Section {
                        H2 { "3. Block Elements" }

                        H3 { "3.1 Blockquote" }
                        BlockQuote {
                            Paragraph {
                                "This is a blockquote. It should be indented and styled distinctly from regular paragraphs."
                            }
                            Paragraph {
                                "— Attribution"
                            }
                        }

                        H3 { "3.2 Preformatted Text" }
                        PreformattedText {
                            Code {
                                "func hello() {\n    print(\"Hello, World!\")\n}"
                            }
                        }
                    }

                    // MARK: - Lists
                    Section {
                        H2 { "4. Lists" }

                        H3 { "4.1 Unordered List" }
                        UnorderedList {
                            ListItem { "First item" }
                            ListItem { "Second item" }
                            ListItem {
                                "Third item with "
                                StrongImportance { "bold" }
                                " text"
                            }
                        }

                        H3 { "4.2 Ordered List" }
                        OrderedList {
                            ListItem { "Step one" }
                            ListItem { "Step two" }
                            ListItem { "Step three" }
                        }
                    }

                    // MARK: - Tables
                    Section {
                        H2 { "5. Tables" }
                        Table {
                            Caption { "Sample Data Table" }
                            TableHead {
                                TableRow {
                                    TableHeader { "Name" }
                                    TableHeader { "Type" }
                                    TableHeader { "Status" }
                                }
                            }
                            TableBody {
                                TableRow {
                                    TableDataCell { "Alpha" }
                                    TableDataCell { "Primary" }
                                    TableDataCell { "Active" }
                                }
                                TableRow {
                                    TableDataCell { "Beta" }
                                    TableDataCell { "Secondary" }
                                    TableDataCell { "Pending" }
                                }
                                TableRow {
                                    TableDataCell { "Gamma" }
                                    TableDataCell { "Tertiary" }
                                    TableDataCell { "Inactive" }
                                }
                            }
                        }
                    }

                    // MARK: - CSS Inline Styles
                    Section {
                        H2 { "6. CSS Inline Styles" }
                        Paragraph {
                            "CSS styling is supported through inline styles:"
                        }
                        ContentDivision {
                            Paragraph { "Default paragraph text." }
                        }
                        .inlineStyle("color", "blue")

                        ContentDivision {
                            Paragraph { "Large font size text." }
                        }
                        .inlineStyle("font-size", "18px")

                        ContentDivision {
                            Paragraph { "Bold weight text via CSS." }
                        }
                        .inlineStyle("font-weight", "bold")

                        ContentDivision {
                            Paragraph { "Italic style text via CSS." }
                        }
                        .inlineStyle("font-style", "italic")
                    }

                    // MARK: - Links
                    Section {
                        H2 { "7. Links" }
                        Paragraph {
                            "Visit "
                            Anchor { "example.com" }
                                .href("https://example.com")
                            " for more information."
                        }
                    }

                    // MARK: - Semantic Containers
                    Section {
                        H2 { "8. Semantic Containers" }

                        Article {
                            H3 { "Nested Article" }
                            Paragraph { "Content inside an article element." }
                        }

                        Aside {
                            H4 { "Aside Content" }
                            Paragraph { "This is supplementary content in an aside." }
                        }

                        NavigationSection {
                            Paragraph { "Navigation section placeholder." }
                        }
                    }

                    // MARK: - Interactive Elements (Static)
                    Section {
                        H2 { "9. Interactive Elements (Static Rendering)" }

                        Details {
                            DisclosureSummary { "Click to expand (shown expanded in PDF)" }
                            Paragraph { "This is the hidden content that would be revealed." }
                        }
                    }

                    // MARK: - Forms (Visual)
                    Section {
                        H2 { "10. Form Elements (Visual Representation)" }

                        Form {
                            FieldSet {
                                Legend { "User Information" }

                                Label { "Name: [text input]" }
                                Label { "Email: [email input]" }
                                Label { "Message:" }
                                Paragraph { "[textarea placeholder]" }

                                Button { "Submit" }
                            }
                        }
                    }

                    // MARK: - Footer
                    Footer {
                        ThematicBreak()
                        Paragraph {
                            Small { "Generated by swift-html-pdf-rendering • \(Date())" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document(
            title: "Comprehensive PDF Test",
            author: "swift-html-pdf-rendering",
            subject: "Feature demonstration"
        ) {
            ComprehensiveView()
        }

        let bytes = [UInt8](document)
        let data = Data(bytes)

        let url = URL(fileURLWithPath: "/private/tmp/swift-pdf-comprehensive.pdf")
        try data.write(to: url)

        // Verify file was created with substantial content
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(bytes.count > 1000, "Comprehensive PDF should have substantial content")

        // Verify multiple pages or substantial operations
        let totalOps = document.pages.reduce(0) { $0 + $1.content.operations.count }
        #expect(totalOps > 50, "Should have many rendering operations")

        print("✅ Comprehensive PDF written to: \(url.path)")
    }
}
