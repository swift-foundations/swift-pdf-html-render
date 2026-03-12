// RowspanTests.swift
// Minimal reproduction of rowspan cell content positioning issue

import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

@Suite
struct RowspanTests {

    /// Minimal test case for rowspan content positioning bug.
    ///
    /// Expected: "Spanning" text appears INSIDE the rowspan cell
    /// Actual: "Spanning" text appears BELOW the table
    @Test
    func `rowspan cell content should appear inside cell`() throws {
        struct MinimalRowspanTable: HTML.View {
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableHeader(rowspan: 2) { "Spanning" }
                            TableDataCell { "Row 1 Data" }
                        }
                        TableRow {
                            // First column skipped due to rowspan
                            TableDataCell { "Row 2 Data" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                MinimalRowspanTable()
            }
        }

        let url = URL(fileURLWithPath: "/tmp/rowspan-minimal-test.pdf")
        try Data([UInt8](document)).write(to: url)

        print("Minimal rowspan test PDF written to: \(url.path)")
    }

    /// Test with multiple rowspan cells to verify the issue persists
    @Test
    func `multiple rowspan cells content positioning`() throws {
        struct MultipleRowspanTable: HTML.View {
            var body: some HTML.View {
                Table {
                    TableHead {
                        TableRow {
                            TableHeader { "Category" }
                            TableHeader { "Item" }
                            TableHeader { "Value" }
                        }
                    }
                    TableBody {
                        TableRow {
                            TableHeader(rowspan: 2) { "Group A" }
                            TableDataCell { "Item 1" }
                            TableDataCell { "100" }
                        }
                        TableRow {
                            TableDataCell { "Item 2" }
                            TableDataCell { "200" }
                        }
                        TableRow {
                            TableHeader(rowspan: 3) { "Group B" }
                            TableDataCell { "Item 3" }
                            TableDataCell { "300" }
                        }
                        TableRow {
                            TableDataCell { "Item 4" }
                            TableDataCell { "400" }
                        }
                        TableRow {
                            TableDataCell { "Item 5" }
                            TableDataCell { "500" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                MultipleRowspanTable()
            }
        }

        let url = URL(fileURLWithPath: "/tmp/rowspan-multiple-test.pdf")
        try Data([UInt8](document)).write(to: url)

        print("Multiple rowspan test PDF written to: \(url.path)")
    }

    /// Control test: table without rowspan should work correctly
    @Test
    func `table without rowspan renders correctly`() throws {
        struct SimpleTable: HTML.View {
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableHeader { "Header 1" }
                            TableHeader { "Header 2" }
                        }
                        TableRow {
                            TableDataCell { "Data 1" }
                            TableDataCell { "Data 2" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                SimpleTable()
            }
        }

        let url = URL(fileURLWithPath: "/tmp/rowspan-control-test.pdf")
        try Data([UInt8](document)).write(to: url)

        print("Control test (no rowspan) PDF written to: \(url.path)")
    }

    /// Test matching 6.6 structure: TableHead with colspan + rowspan in body + TableFoot
    @Test
    func `rowspan with thead colspan and tfoot`() throws {
        struct ComplexTable: HTML.View {
            var body: some HTML.View {
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
                            TableDataCell { "OK" }
                        }
                        TableRow {
                            TableDataCell { "Lists" }
                            TableDataCell { "Full support" }
                            TableDataCell { "OK" }
                        }
                        TableRow {
                            TableHeader(rowspan: 3) { "Typography" }
                            TableDataCell { "Headings" }
                            TableDataCell { "H1-H6" }
                            TableDataCell { "OK" }
                        }
                        TableRow {
                            TableDataCell { "Inline styles" }
                            TableDataCell { "Bold, italic" }
                            TableDataCell { "OK" }
                        }
                        TableRow {
                            TableDataCell { "Links" }
                            TableDataCell { "Clickable" }
                            TableDataCell { "OK" }
                        }
                    }
                    TableFoot {
                        TableRow {
                            TableDataCell(colspan: 4) { "All features implemented" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                ComplexTable()
            }
        }

        let url = URL(fileURLWithPath: "/tmp/rowspan-complex-test.pdf")
        try Data([UInt8](document)).write(to: url)

        print("Complex rowspan test (matching 6.6) PDF written to: \(url.path)")
    }
}
