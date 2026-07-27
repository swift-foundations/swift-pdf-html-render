// IterativeTupleTests.swift
// Verify iterative _Tuple rendering eliminates stack overflow
// from deeply nested buildPartialBlock binary trees.

import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering_Test_Support

@Suite
struct `Iterative Tuple Tests` {

    private func render<V: HTML.View>(_ view: V) -> [UInt8] {
        let document = PDF.Document {
            HTML.Document { view }
        }
        return [UInt8](document)
    }

    // MARK: - Tables (primary crash scenario)

    @Test
    func `10x10 table renders without stack overflow`() {
        let bytes = render(Table10x10())
        #expect(!bytes.isEmpty)
    }

    @Test
    func `10x30 table renders without stack overflow`() {
        let bytes = render(Table10x30())
        #expect(!bytes.isEmpty)
    }

    @Test
    func `5-column styled table renders without stack overflow`() {
        let bytes = render(StyledTable5x10())
        #expect(!bytes.isEmpty)
    }

    // MARK: - Deep flat view hierarchies

    @Test
    func `30-element flat view body renders without stack overflow`() {
        let bytes = render(FlatView30())
        #expect(!bytes.isEmpty)
    }

    @Test
    func `50-element flat view body renders without stack overflow`() {
        let bytes = render(FlatView50())
        #expect(!bytes.isEmpty)
    }
}

// MARK: - Test Views

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

private struct Table10x10: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead {
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
            TableBody {
                Rows10x10()
            }
        }
    }
}

private struct Table10x30: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead {
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
            TableBody {
                Rows10x10()
                Rows10x10()
                Rows10x10()
            }
        }
    }
}

private struct StyledTable5x10: HTML.View {
    var body: some HTML.View {
        Table {
            TableHead {
                TableRow {
                    TableHeader { "Name" }
                    TableHeader { "Age" }
                    TableHeader { "City" }
                    TableHeader { "Role" }
                    TableHeader { "Status" }
                }
            }
            TableBody {
                StyledRow5()
                StyledRow5()
                StyledRow5()
                StyledRow5()
                StyledRow5()
                StyledRow5()
                StyledRow5()
                StyledRow5()
                StyledRow5()
                StyledRow5()
            }
        }
    }
}

private struct StyledRow5: HTML.View {
    var body: some HTML.View {
        TableRow {
            TableDataCell { "Alice" }
            TableDataCell { "30" }
            TableDataCell { "Amsterdam" }
            TableDataCell { "Engineer" }
            TableDataCell { "Active" }
        }
    }
}

private struct FlatView30: HTML.View {
    var body: some HTML.View {
        Paragraph { "Line 1" }
        Paragraph { "Line 2" }
        Paragraph { "Line 3" }
        Paragraph { "Line 4" }
        Paragraph { "Line 5" }
        Paragraph { "Line 6" }
        Paragraph { "Line 7" }
        Paragraph { "Line 8" }
        Paragraph { "Line 9" }
        Paragraph { "Line 10" }
        Paragraph { "Line 11" }
        Paragraph { "Line 12" }
        Paragraph { "Line 13" }
        Paragraph { "Line 14" }
        Paragraph { "Line 15" }
        Paragraph { "Line 16" }
        Paragraph { "Line 17" }
        Paragraph { "Line 18" }
        Paragraph { "Line 19" }
        Paragraph { "Line 20" }
        Paragraph { "Line 21" }
        Paragraph { "Line 22" }
        Paragraph { "Line 23" }
        Paragraph { "Line 24" }
        Paragraph { "Line 25" }
        Paragraph { "Line 26" }
        Paragraph { "Line 27" }
        Paragraph { "Line 28" }
        Paragraph { "Line 29" }
        Paragraph { "Line 30" }
    }
}

private struct FlatView50: HTML.View {
    var body: some HTML.View {
        FlatView30()
        Paragraph { "Line 31" }
        Paragraph { "Line 32" }
        Paragraph { "Line 33" }
        Paragraph { "Line 34" }
        Paragraph { "Line 35" }
        Paragraph { "Line 36" }
        Paragraph { "Line 37" }
        Paragraph { "Line 38" }
        Paragraph { "Line 39" }
        Paragraph { "Line 40" }
        Paragraph { "Line 41" }
        Paragraph { "Line 42" }
        Paragraph { "Line 43" }
        Paragraph { "Line 44" }
        Paragraph { "Line 45" }
        Paragraph { "Line 46" }
        Paragraph { "Line 47" }
        Paragraph { "Line 48" }
        Paragraph { "Line 49" }
        Paragraph { "Line 50" }
    }
}
