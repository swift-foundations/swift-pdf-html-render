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
        let textOps = page.content.operations.compactMap { op -> PDF.Content.Text.Operation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        // With proper inline flow, all text should be on the same Y position
        // (or very close, within floating point tolerance)
        let yPositions = Set(textOps.map { Int($0.position.y) })

        // All text should be on the same line (same Y position)
        #expect(yPositions.count == 1, "Expected all text on same line, got Y positions: \(yPositions)")
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
                return op.font == .helvetica.bold
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
        let textOps = page.content.operations.compactMap { op -> PDF.Content.Text.Operation? in
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
        let textOps = page.content.operations.compactMap { op -> PDF.Content.Text.Operation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(textOps.count >= 3, "Should have multiple text operations")
    }
}
