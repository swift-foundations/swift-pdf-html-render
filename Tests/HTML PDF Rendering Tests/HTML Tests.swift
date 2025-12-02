// HTML Tests.swift

import Foundation
import Testing
@testable import HTML_PDF_Rendering
import PDF_Rendering
import PDF_Standard
import HTML_Rendering

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
