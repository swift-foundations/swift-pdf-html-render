//
//  File.swift
//  swift-html-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 03/12/2025.
//

//import HtmlToPdf
import Foundation
import Testing
@testable import HTML_PDF_Rendering
import PDF_Rendering
import PDF_Standard
import HTML_Rendering
import CSS

@Suite
struct `Comprehensive Visual Tests HTML to PDF` {

    @Test("Comprehensive document with all features")
    func comprehensiveDocument() async throws {
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

                        H3 { "4.3 Nested Lists" }
                        UnorderedList {
                            ListItem { "Parent item 1" }
                            ListItem {
                                "Parent item 2 with nested list:"
                                UnorderedList {
                                    ListItem { "Child item A" }
                                    ListItem { "Child item B" }
                                }
                            }
                            ListItem { "Parent item 3" }
                        }
                    }

                    // MARK: - Tables
                    Section {
                        H2 { "5. Tables" }

                        H3 { "5.1 Simple Table" }
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

                        H3 { "5.2 Table with Styled Cells" }
                        Table {
                            TableHead {
                                TableRow {
                                    TableHeader { "Feature" }
                                    TableHeader { "Support" }
                                    TableHeader { "Notes" }
                                }
                            }
                            TableBody {
                                TableRow {
                                    TableDataCell {
                                        StrongImportance { "Headings" }
                                    }
                                    TableDataCell { "Full" }
                                    TableDataCell { "H1-H6 supported" }
                                }
                                TableRow {
                                    TableDataCell {
                                        StrongImportance { "Text Styling" }
                                    }
                                    TableDataCell { "Full" }
                                    TableDataCell { "Bold, italic, underline" }
                                }
                                TableRow {
                                    TableDataCell {
                                        StrongImportance { "Lists" }
                                    }
                                    TableDataCell { "Full" }
                                    TableDataCell { "Ordered and unordered" }
                                }
                                TableRow {
                                    TableDataCell {
                                        StrongImportance { "Tables" }
                                    }
                                    TableDataCell { "Partial" }
                                    TableDataCell { "Basic support" }
                                }
                            }
                            TableFoot {
                                TableRow {
                                    TableDataCell { "Total Features" }
                                    TableDataCell { "4" }
                                    TableDataCell { "" }
                                }
                            }
                        }

                        H3 { "5.3 Numeric Data Table" }
                        Table {
                            Caption { "Quarterly Sales Report" }
                            TableHead {
                                TableRow {
                                    TableHeader { "Quarter" }
                                    TableHeader { "Revenue" }
                                    TableHeader { "Growth" }
                                }
                            }
                            TableBody {
                                TableRow {
                                    TableDataCell { "Q1 2024" }
                                    TableDataCell { "$125,000" }
                                    TableDataCell { "+15%" }
                                }
                                TableRow {
                                    TableDataCell { "Q2 2024" }
                                    TableDataCell { "$142,500" }
                                    TableDataCell { "+14%" }
                                }
                                TableRow {
                                    TableDataCell { "Q3 2024" }
                                    TableDataCell { "$156,000" }
                                    TableDataCell { "+9%" }
                                }
                                TableRow {
                                    TableDataCell { "Q4 2024" }
                                    TableDataCell { "$178,200" }
                                    TableDataCell { "+12%" }
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

                        Paragraph { "Default paragraph text (no styling)." }

                        Paragraph { "Blue colored text." }
                            .inlineStyle("color", "blue")

                        Paragraph { "Red colored text." }
                            .inlineStyle("color", "red")

                        Paragraph { "Large font size text (18px)." }
                            .inlineStyle("font-size", "18px")

                        Paragraph { "Extra large font size text (24px)." }
                            .inlineStyle("font-size", "24px")

                        Paragraph { "Bold weight text via CSS." }
                            .inlineStyle("font-weight", "bold")

                        Paragraph { "Italic style text via CSS." }
                            .inlineStyle("font-style", "italic")

                        Paragraph { "Combined: Bold + Italic + Blue" }
                            .inlineStyle("font-weight", "bold")
                            .inlineStyle("font-style", "italic")
                            .inlineStyle("color", "blue")
                    }

                    // MARK: - CSS Fluent API
                    Section {
                        H2 { "7. CSS Fluent API" }

                        Paragraph { "Using .css fluent API for styling:" }

                        Paragraph { "Green text via .css.color()" }
                            .css
                            .color(.green)

                        Paragraph { "20px font via .css.fontSize()" }
                            .css
                            .fontSize(.px(20))

                        Paragraph { "Bold via .css.fontWeight()" }
                            .css
                            .fontWeight(.bold)

                        Paragraph { "Multiple styles chained" }
                            .css
                            .color(.purple)
                            .fontSize(.px(16))
                            .fontWeight(.bold)
                    }

                    // MARK: - Links
                    Section {
                        H2 { "8. Links" }
                        Paragraph {
                            "Visit "
                            Anchor { "example.com" }
                                .href("https://example.com")
                            " for more information."
                        }
                        Paragraph {
                            "Multiple links: "
                            Anchor { "Google" }
                                .href("https://google.com")
                            ", "
                            Anchor { "GitHub" }
                                .href("https://github.com")
                            ", "
                            Anchor { "Swift.org" }
                                .href("https://swift.org")
                        }
                    }

                    // MARK: - Semantic Containers
                    Section {
                        H2 { "9. Semantic Containers" }

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
                        H2 { "10. Interactive Elements (Static Rendering)" }

                        Details {
                            DisclosureSummary { "Click to expand (shown expanded in PDF)" }
                            Paragraph { "This is the hidden content that would be revealed." }
                        }
                    }

                    // MARK: - Forms (Visual)
                    Section {
                        H2 { "11. Form Elements (Visual Representation)" }

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

                    // MARK: - Figure and Image placeholders
                    Section {
                        H2 { "12. Figures" }

                        Figure {
                            Paragraph { "[Image placeholder - 300x200]" }
                            FigureCaption { "Figure 1: Example image placeholder" }
                        }

                        Figure {
                            Paragraph { "[Chart placeholder - 400x250]" }
                            FigureCaption { "Figure 2: Data visualization placeholder" }
                        }
                    }

                    // MARK: - Definition List Style
                    Section {
                        H2 { "13. Definition-Style Content" }

                        Paragraph {
                            StrongImportance { "HTML" }
                        }
                        Paragraph { "HyperText Markup Language - the standard markup language for documents designed to be displayed in a web browser." }
                            .inlineStyle("margin-left", "20px")

                        Paragraph {
                            StrongImportance { "PDF" }
                        }
                        Paragraph { "Portable Document Format - a file format developed to present documents consistently across devices." }
                            .inlineStyle("margin-left", "20px")

                        Paragraph {
                            StrongImportance { "Swift" }
                        }
                        Paragraph { "A powerful and intuitive programming language for iOS, macOS, watchOS, tvOS, and beyond." }
                            .inlineStyle("margin-left", "20px")
                    }

                    // MARK: - Footer
                    Footer {
                        ThematicBreak()
                        Paragraph {
                            Small { "Generated by swift-html-pdf-rendering" }
                        }
                        Paragraph {
                            Small { "Test executed: \(Date())" }
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
        
        
        
//        @Dependency(\.pdf) var pdf
//        _ = try await pdf.render(
//            html: String(ComprehensiveView()),
//            to: URL(fileURLWithPath: "/private/tmp/swift-pdf-comprehensive-html-to-pdf.pdf")
//        )

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

        // Print diagnostic information
        print("✅ Comprehensive PDF written to: \(url.path)")
        print("📄 Pages: \(document.pages.count)")
        print("📦 File size: \(bytes.count) bytes")
        print("🔧 Total operations: \(totalOps)")

        // Count specific operation types
        var textOps = 0
        var graphicsOps = 0
        for page in document.pages {
            for op in page.content.operations {
                switch op {
                case .text: textOps += 1
                case .graphics: graphicsOps += 1
                }
            }
        }
        print("📝 Text operations: \(textOps)")
        print("🎨 Graphics operations: \(graphicsOps)")
    }
}
