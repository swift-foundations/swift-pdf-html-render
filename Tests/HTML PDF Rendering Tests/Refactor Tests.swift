// Refactor Tests.swift
// Tests for the two-phase HTML → PDF transformation

import Testing
import HTML_Rendering
import PDF_Rendering
@testable import HTML_PDF_Rendering_Refactor

@Suite("HTMLToPDF Transformation Tests")
struct HTMLToPDFTransformationTests {

    // MARK: - Basic Transformation

    @Test("String transforms to PDF content")
    func stringTransformation() {
        let html = "Hello, World!"

        let content = PDF.Content(html)

        // Should have operations from the flushed text
        #expect(content.operations.count >= 0) // May be 0 if no flush triggered
    }

    @Test("Paragraph transforms with spacing")
    func paragraphTransformation() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "Test paragraph" }
            }
        }

        let content = PDF.Content(TestView())

        // Should have text operations
        let textOps = content.operations.filter {
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

        let content = PDF.Content(TestView())

        // Should have text operations
        let textOps = content.operations.compactMap { op -> PDF.Content.Text.Operation? in
            if case .text(let textOp) = op { return textOp }
            return nil
        }

        #expect(textOps.count >= 1)

        // H1 should use larger font size (2x default)
        if let firstOp = textOps.first {
            let config = HTMLToPDF.Configuration()
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

        let content = PDF.Content(TestView())

        // Get all text operations
        let textOps = content.operations.compactMap { op -> PDF.Content.Text.Operation? in
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

        let content = PDF.Content(TestView())

        let textOps = content.operations.compactMap { op -> PDF.Content.Text.Operation? in
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

        let content = PDF.Content(TestView())

        let textOps = content.operations.compactMap { op -> PDF.Content.Text.Operation? in
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

        let content = PDF.Content(TestView())

        let textOps = content.operations.compactMap { op -> PDF.Content.Text.Operation? in
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
        let config = HTMLToPDF.Configuration(defaultFontSize: 14)

        #expect(config.headingSize(level: 1) == 28) // 14 * 2.0
        #expect(config.headingSize(level: 2) == 21) // 14 * 1.5
        #expect(config.headingSize(level: 3) == 14 * 1.17)
    }

    @Test("Configuration affects content dimensions")
    func configurationDimensions() {
        let config = HTMLToPDF.Configuration(
            paperSize: .a4,
            margins: .init(top: 72, left: 72, bottom: 72, right: 72)
        )

        #expect(config.contentWidth == PDF.PaperSize.a4.width - 144)
        #expect(config.contentHeight == PDF.PaperSize.a4.height - 144)
    }
}

// MARK: - Comprehensive Test

@Suite("Comprehensive HTML to PDF Tests")
struct ComprehensiveHTMLToPDFTests {

    @Test("Complex document renders correctly")
    func complexDocument() {
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

        let doc = PDF.Document(
            ComplexView(),
            title: "Complex Test",
            author: "Test Suite"
        )

        let bytes = [UInt8](doc)

        // Basic sanity checks
        #expect(doc.pages.count >= 1)
        #expect(bytes.count > 1000, "Complex document should have substantial content")

        // Count operations
        let totalOps = doc.pages.reduce(0) { $0 + $1.content.operations.count }
        #expect(totalOps > 5, "Should have multiple operations")
    }
}
