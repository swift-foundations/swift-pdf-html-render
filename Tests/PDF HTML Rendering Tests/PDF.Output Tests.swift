// PDF.Output Tests.swift
// Visual inspection tests - writes PDFs to /tmp

import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

@Suite
struct PDFOutputTests {
    @Test
    func writesBasicHTMLToPDF() throws {
        struct SampleDocument: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    H1 { "HTML to PDF Test Document" }

                    Paragraph {
                        "This document demonstrates basic HTML to PDF rendering."
                    }

                    H2 { "Text Formatting" }

                    Paragraph {
                        "Normal text with "
                        StrongImportance { "bold" }
                        " and "
                        Emphasis { "italic" }
                        " formatting."
                    }

                    H2 { "Lists" }

                    UnorderedList {
                        ListItem { "First item" }
                        ListItem { "Second item" }
                        ListItem { "Third item" }
                    }

                    H2 { "Ordered List" }

                    OrderedList {
                        ListItem { "Step one" }
                        ListItem { "Step two" }
                        ListItem { "Step three" }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                SampleDocument()
            }
        }

        let bytes = [UInt8](document)
        let path = try PDFOutput.write(bytes, name: "basic-html")

        print("PDF written to: \(path)")
        #expect(!bytes.isEmpty)
    }

    @Test
    func writesTableToPDF() throws {
        struct TableDocument: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    H1 { "Table Test" }

                    Table {
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
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                TableDocument()
            }
        }

        let bytes = [UInt8](document)
        let path = try PDFOutput.write(bytes, name: "table")

        print("PDF written to: \(path)")
        #expect(!bytes.isEmpty)
    }

    @Test
    func writesMultiPageToPDF() throws {
        struct MultiPageDocument: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    H1 { "Multi-Page Document" }

                    for i in 1...30 {
                        Paragraph {
                            "Paragraph \(i): This is some sample content that helps fill the page. When enough paragraphs accumulate, the content will flow onto subsequent pages. This tests the page break handling in the HTML to PDF renderer."
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                MultiPageDocument()
            }
        }

        let bytes = [UInt8](document)
        let path = try PDFOutput.write(bytes, name: "multi-page")

        print("PDF written to: \(path)")
        #expect(!bytes.isEmpty)
    }

    @Test
    func writesStyledHTMLToPDF() throws {
        struct StyledDocument: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    H1 { "Styled Document" }
                        .css
                        .color(.hex("#333"))

                    Paragraph {
                        "This paragraph has custom styling applied."
                    }
                    .css
                    .padding(.px(10))
                    .backgroundColor(.hex("#f0f0f0"))

                    ContentDivision {
                        Paragraph { "Box with border" }
                    }
                    .css
                    //                    .border(.px(1), .solid, .hex("#ccc"))
                    .padding(.px(20))
                    .margin(.px(10))
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                StyledDocument()
            }
        }

        let bytes = [UInt8](document)
        let path = try PDFOutput.write(bytes, name: "styled")

        print("PDF written to: \(path)")
        #expect(!bytes.isEmpty)
    }
}
