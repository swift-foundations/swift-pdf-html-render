//
//  Rowspan Snapshot Tests.swift
//  swift-pdf-html-rendering
//

import HTML_Rendering
import PDF_HTML_Rendering
import PDF_Rendering
import Test_Snapshot_Primitives
import Testing
import Tests_Inline_Snapshot

@Suite
struct `Rowspan Snapshot Tests` {
    @Suite struct Snapshot {}
}

// MARK: - Snapshot

extension RowspanSnapshotTests.Snapshot {
    @Test
    func `minimal rowspan`() {
        let document = PDF.Document {
            HTML.Document {
                Table {
                    TableBody {
                        TableRow {
                            TableHeader(rowspan: 2) { "Spanning" }
                            TableDataCell { "Row 1 Data" }
                        }
                        TableRow {
                            TableDataCell { "Row 2 Data" }
                        }
                    }
                }
            }
        }

        snapshot(as: .pdf, named: "rowspan-minimal") { document }
    }

    @Test
    func `multiple rowspan cells`() {
        let document = PDF.Document {
            HTML.Document {
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

        snapshot(as: .pdf, named: "rowspan-multiple") { document }
    }

    @Test
    func `table without rowspan`() {
        let document = PDF.Document {
            HTML.Document {
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

        snapshot(as: .pdf, named: "rowspan-control") { document }
    }

    @Test
    func `complex rowspan with colspan and tfoot`() {
        let document = PDF.Document {
            HTML.Document {
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

        snapshot(as: .pdf, named: "rowspan-complex") { document }
    }
}
