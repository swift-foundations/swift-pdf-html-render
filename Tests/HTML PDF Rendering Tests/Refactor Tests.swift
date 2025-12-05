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

// MARK: - Comprehensive Test

@Suite
struct `Comprehensive PDF.HTML.View Tests` {

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

        // Recitals
        H2 { "RECITALS" }

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

        // Article 1
        H2 { "ARTICLE 1: DEFINITIONS" }

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

        // Article 2
        H2 { "ARTICLE 2: OBLIGATIONS OF RECIPIENT" }

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

        // Article 3
        H2 { "ARTICLE 3: TERM AND TERMINATION" }

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

        // Article 4
        H2 { "ARTICLE 4: GENERAL PROVISIONS" }

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

        // Signature block
        H2 { "SIGNATURES" }

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
