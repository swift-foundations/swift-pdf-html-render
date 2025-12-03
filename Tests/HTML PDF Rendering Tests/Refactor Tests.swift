// Refactor Tests.swift
// Tests for the two-phase HTML → PDF transformation

import Testing
import Foundation
import HTML_Rendering
import PDF_Rendering
@testable import HTML_PDF_Rendering

@Suite("PDF.HTML.View Tests")
struct PDFHTMLViewTests {

    // MARK: - Basic Transformation

    @Test("String transforms to PDF content")
    func stringTransformation() {
        let html = "Hello, World!"
        let (pages, _) = PDF.HTML.pages(from: html)

        // Should have at least one page
        #expect(pages.count >= 1)
    }

    @Test("Paragraph transforms with spacing")
    func paragraphTransformation() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Test paragraph" }
            }
        }

        let (pages, _) = PDF.HTML.pages(from: TestView())

        // Should have operations
        let ops = pages.first ?? []
        let textOps = ops.filter {
            if case .text = $0 { return true }
            return false
        }
        #expect(textOps.count >= 1)
    }

    @Test("Heading transforms with larger font")
    func headingTransformation() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                H1 { "Big Heading" }
            }
        }

        let (pages, _) = PDF.HTML.pages(from: TestView())
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

    @Test("Inline elements stay on same line")
    func inlineFlow() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    "Normal "
                    StrongImportance { "bold" }
                    " normal"
                }
            }
        }

        let (pages, _) = PDF.HTML.pages(from: TestView())
        let ops = pages.first ?? []

        // Get all text operations
        let textOps = ops.compactMap { op -> PDF.Render.TextOperation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        // All text should be on the same Y position (same line)
        let yPositions = Set(textOps.map { Int($0.position.y) })
        #expect(yPositions.count == 1, "Expected all text on same line, got Y positions: \(yPositions)")
    }

    @Test("Bold applies correct font variant")
    func boldFont() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    StrongImportance { "Bold text" }
                }
            }
        }

        let (pages, _) = PDF.HTML.pages(from: TestView())
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

    @Test("Italic applies correct font variant")
    func italicFont() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    Emphasis { "Italic text" }
                }
            }
        }

        let (pages, _) = PDF.HTML.pages(from: TestView())
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

    @Test("Bold + Italic combines correctly")
    func boldItalicFont() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    StrongImportance {
                        Emphasis { "Bold italic" }
                    }
                }
            }
        }

        let (pages, _) = PDF.HTML.pages(from: TestView())
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

    @Test("PDF.Document can be created from HTML")
    func documentCreation() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                H1 { "Title" }
                Paragraph { "Content" }
            }
        }

        let doc = PDF.Document(TestView(), title: "Test")

        #expect(doc.pages.count >= 1)
        #expect(doc.info?.title == "Test")
    }

    @Test("PDF bytes can be generated from HTML")
    func bytesGeneration() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Hello PDF" }
            }
        }

        let doc = PDF.Document(TestView())
        let bytes = [UInt8](doc)

        // Should start with %PDF
        #expect(bytes.count > 0)
        #expect(bytes.starts(with: [0x25, 0x50, 0x44, 0x46])) // %PDF
    }

    // MARK: - Configuration

    @Test("Configuration affects heading sizes")
    func configurationHeadingSizes() {
        let config = PDF.HTML.Configuration(defaultFontSize: 14)

        #expect(config.headingSize(level: 1) == 28) // 14 * 2.0
        #expect(config.headingSize(level: 2) == 21) // 14 * 1.5
        #expect(config.headingSize(level: 3) == 14 * 1.17)
    }

    @Test("Configuration affects content dimensions")
    func configurationDimensions() {
        let config = PDF.HTML.Configuration(
            paperSize: .a4,
            margins: .init(top: 72, left: 72, bottom: 72, right: 72)
        )

        #expect(config.contentWidth == PDF.PaperSize.a4.width - 144)
        #expect(config.contentHeight == PDF.PaperSize.a4.height - 144)
    }
}

// MARK: - Comprehensive Test

@Suite("Comprehensive PDF.HTML.View Tests")
struct ComprehensivePDFHTMLViewTests {

    @Test("Complex document renders correctly")
    func complexDocument() throws {
        struct ComplexView: HTML.View {
            var body: some HTML.View {
                Article {
                    Header {
                        H1 { "Document Title" }
                    }

                    Section {
                        H2 { "Introduction" }
                        Paragraph {
                            "This is a "
                            StrongImportance { "comprehensive" }
                            " test of the "
                            Emphasis { "two-phase transformation" }
                            " approach."
                        }
                    }

                    Section {
                        H2 { "Details" }
                        Paragraph { "More content here." }
                        Paragraph {
                            "With "
                            StrongImportance {
                                Emphasis { "bold italic" }
                            }
                            " text."
                        }
                    }

                    Footer {
                        Paragraph { "End of document" }
                    }
                }
            }
        }

        let doc = PDF.Document.init(
            ComplexView(),
            title: "Complex Test",
            author: "Test Suite"
        )

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
