// Table Performance Tests.swift
// Performance benchmarks for HTML table rendering

import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

extension PDF {
    #Tests
}

// Helper to render HTML views to PDF
private func render<V: HTML.View>(_ view: V) {
    let document = PDF.Document {
        HTML.Document { view }
    }
    let _ = [UInt8](document)
}

// MARK: - Simple Table Scaling

extension PDF.Test.Performance {

    @Test(.timed(iterations: 20, warmup: 3))
    func `simple table 5x10`() {
        render(SimpleTable5x10())
    }

    @Test(.timed(iterations: 10, warmup: 2))
    func `simple table 10x50`() {
        render(SimpleTable10x50())
    }

    @Test(.timed(iterations: 5, warmup: 1))
    func `simple table 10x100`() {
        render(SimpleTable10x100())
    }

    // MARK: - Scaling at Various Sizes

    @Test(.timed(iterations: 20, warmup: 3))
    func `simple table 10x1`() {
        render(SimpleTable10x1())
    }

    @Test(.timed(iterations: 20, warmup: 3))
    func `simple table 10x2`() {
        render(SimpleTable10x2())
    }

    @Test(.timed(iterations: 20, warmup: 3))
    func `simple table 10x5`() {
        render(SimpleTable10x5())
    }

    @Test(.timed(iterations: 20, warmup: 3))
    func `simple table 10x10`() {
        render(SimpleTable10x10())
    }

    @Test(.timed(iterations: 10, warmup: 2))
    func `simple table 10x25`() {
        render(SimpleTable10x25())
    }

    // MARK: - Rowspan Tests (Mirror reflection)

    @Test(.timed(iterations: 10, warmup: 2))
    func `table with rowspan 30 rows`() {
        render(RowspanTable30())
    }

    // MARK: - Complex Table

    @Test(.timed(iterations: 5, warmup: 1))
    func `complex table mixed spans`() {
        render(ComplexTable30())
    }

    // MARK: - Throughput

    @Test(.timed(iterations: 500, warmup: 50))
    func `throughput single table 5x10`() {
        render(SimpleTable5x10())
    }

    // MARK: - Span Overhead Comparison

    @Test(.timed(iterations: 10, warmup: 2))
    func `simple table 5x30`() {
        render(SimpleTable5x30())
    }
}

// MARK: - Pre-defined Table Structures

private struct SimpleTable5x10: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead {
                TableRow {
                    TableHeader { "H1" }
                    TableHeader { "H2" }
                    TableHeader { "H3" }
                    TableHeader { "H4" }
                    TableHeader { "H5" }
                }
            }
            TableBody {
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
            }
        }
    }
}

private struct Row5: HTML.View {
    var body: some HTML.View {
        TableRow {
            TableDataCell { "C1" }
            TableDataCell { "C2" }
            TableDataCell { "C3" }
            TableDataCell { "C4" }
            TableDataCell { "C5" }
        }
    }
}

private struct Row10: HTML.View {
    var body: some HTML.View {
        TableRow {
            TableDataCell { "C1" }
            TableDataCell { "C2" }
            TableDataCell { "C3" }
            TableDataCell { "C4" }
            TableDataCell { "C5" }
            TableDataCell { "C6" }
            TableDataCell { "C7" }
            TableDataCell { "C8" }
            TableDataCell { "C9" }
            TableDataCell { "C10" }
        }
    }
}

private struct Header10: HTML.View {
    var body: some HTML.View {
        TableRow {
            TableHeader { "H1" }
            TableHeader { "H2" }
            TableHeader { "H3" }
            TableHeader { "H4" }
            TableHeader { "H5" }
            TableHeader { "H6" }
            TableHeader { "H7" }
            TableHeader { "H8" }
            TableHeader { "H9" }
            TableHeader { "H10" }
        }
    }
}

private struct Rows10x10: HTML.View {
    var body: some HTML.View {
        Row10()
        Row10()
        Row10()
        Row10()
        Row10()
        Row10()
        Row10()
        Row10()
        Row10()
        Row10()
    }
}

private struct SimpleTable10x1: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead { Header10() }
            TableBody { Row10() }
        }
    }
}

private struct SimpleTable10x2: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead { Header10() }
            TableBody {
                Row10()
                Row10()
            }
        }
    }
}

private struct SimpleTable10x5: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead { Header10() }
            TableBody {
                Row10()
                Row10()
                Row10()
                Row10()
                Row10()
            }
        }
    }
}

private struct SimpleTable10x10: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead { Header10() }
            TableBody { Rows10x10() }
        }
    }
}

private struct SimpleTable10x25: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead { Header10() }
            TableBody {
                Rows10x10()
                Rows10x10()
                Row10()
                Row10()
                Row10()
                Row10()
                Row10()
            }
        }
    }
}

private struct SimpleTable10x50: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead { Header10() }
            TableBody {
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
            }
        }
    }
}

private struct SimpleTable10x100: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead { Header10() }
            TableBody {
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
                Rows10x10()
            }
        }
    }
}

private struct SimpleTable5x30: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead {
                TableRow {
                    TableHeader { "H1" }
                    TableHeader { "H2" }
                    TableHeader { "H3" }
                    TableHeader { "H4" }
                    TableHeader { "H5" }
                }
            }
            TableBody {
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
                Row5()
            }
        }
    }
}

private struct RowspanGroup: HTML.View {
    var body: some HTML.View {
        TableRow {
            TableHeader(rowspan: 3) { "Group" }
            TableDataCell { "Item 1" }
            TableDataCell { "100" }
        }
        TableRow {
            TableDataCell { "Item 2" }
            TableDataCell { "200" }
        }
        TableRow {
            TableDataCell { "Item 3" }
            TableDataCell { "300" }
        }
    }
}

private struct RowspanTable30: HTML.View {
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
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
                RowspanGroup()
            }
        }
    }
}

private struct ComplexGroup: HTML.View {
    var body: some HTML.View {
        TableRow {
            TableHeader(rowspan: 3) { "Group" }
            TableDataCell { "Sub A" }
            TableDataCell { "Val A" }
            TableDataCell { "OK" }
        }
        TableRow {
            TableDataCell { "Sub B" }
            TableDataCell { "Val B" }
            TableDataCell { "OK" }
        }
        TableRow {
            TableDataCell(colspan: 2) { "Combined" }
            TableDataCell { "OK" }
        }
    }
}

private struct ComplexTable30: HTML.View {
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
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
                ComplexGroup()
            }
            TableFoot {
                TableRow {
                    TableDataCell(colspan: 4) { "Total: 30 items" }
                }
            }
        }
    }
}
