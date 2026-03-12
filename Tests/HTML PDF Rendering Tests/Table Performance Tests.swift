// Table Performance Tests.swift
// Performance benchmarks for HTML table rendering

import Foundation
import Testing
import Test_Primitives
import HTML_Rendering
import PDF_Rendering
@testable import PDF_HTML_Rendering

extension Tag {
    @Tag static var performance: Self
    @Tag static var tables: Self
}

// Helper to render HTML views to PDF
private func render<V: HTML.View>(_ view: V) {
    let document = PDF.Document {
        HTML.Document { view }
    }
    let _ = [UInt8](document)
}

@Suite("Table Performance Tests", .serialized, .tags(.performance, .tables))
struct TablePerformanceTests {

    // MARK: - Simple Table Scaling

    @Test("Simple table: 5x10", .timed(iterations: 20, warmup: 3))
    func simpleTable5x10() {
        struct TestTable: HTML.View {
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell { "C1" }
                            TableDataCell { "C2" }
                            TableDataCell { "C3" }
                        }
                    }
                }
            }
        }

        let document = PDF.Document {
            HTML.Document {
                TestTable()
            }
        }
        let _ = [UInt8](document)
    }

    @Test("Simple table: 10x50", .timed(iterations: 10, warmup: 2))
    func simpleTable10x50() {
        render(SimpleTable10x50())
    }

    @Test("Simple table: 10x100", .timed(iterations: 5, warmup: 1))
    func simpleTable10x100() {
        render(SimpleTable10x100())
    }

    // MARK: - Rowspan Tests (Mirror reflection)

    @Test("Table with rowspan: 30 rows", .timed(iterations: 10, warmup: 2))
    func tableWithRowspan() {
        render(RowspanTable30())
    }

    // MARK: - Complex Table

    @Test("Complex table: mixed spans", .timed(iterations: 5, warmup: 1))
    func complexTable() {
        render(ComplexTable30())
    }

    // MARK: - Throughput Test

    @Test("Throughput (5 second run)")
    func throughput() {
        let duration: Duration = .seconds(5)
        let start = ContinuousClock.now
        var count = 0

        while ContinuousClock.now - start < duration {
            render(SimpleTable5x10())
            count += 1
        }

        let elapsed = ContinuousClock.now - start
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        let throughput = Double(count) / seconds

        print("📊 Throughput: \(Int(throughput)) tables/sec (\(count) in \(String(format: "%.2f", seconds))s)")
    }

    // MARK: - Scaling Analysis

    @Test("Scaling analysis (O(n) vs O(n²))")
    func scalingAnalysis() {
        let tests: [(name: String, rows: Int, render: () -> Void)] = [
            ("10 rows", 10, { render(SimpleTable10x10()) }),
            ("25 rows", 25, { render(SimpleTable10x25()) }),
            ("50 rows", 50, { render(SimpleTable10x50()) }),
            ("100 rows", 100, { render(SimpleTable10x100()) }),
        ]

        var results: [(rows: Int, time: Double)] = []

        for test in tests {
            let iterations = max(1, 50 / test.rows)
            var totalTime: Double = 0

            for _ in 0..<iterations {
                let start = ContinuousClock.now
                test.render()
                let elapsed = ContinuousClock.now - start
                totalTime += Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            }

            results.append((test.rows, totalTime / Double(iterations)))
        }

        print("\n📊 Table Scaling Analysis (10 columns)")
        print("┌─────────┬──────────────┬─────────────┬─────────────┐")
        print("│ Rows    │ Time (ms)    │ Per-row     │ Scaling     │")
        print("├─────────┼──────────────┼─────────────┼─────────────┤")

        var previousPerRow: Double?
        for (rows, time) in results {
            let timeMs = time * 1000
            let perRow = timeMs / Double(rows)

            let scaling: String
            if let prev = previousPerRow {
                let ratio = perRow / prev
                if ratio > 1.5 {
                    scaling = "⚠️  O(n²)"
                } else if ratio > 1.1 {
                    scaling = "⚡ ~O(n log n)"
                } else {
                    scaling = "✅ O(n)"
                }
            } else {
                scaling = "baseline"
            }

            print("│ \(String(format: "%5d", rows).padding(toLength: 7, withPad: " ", startingAt: 0)) │ \(String(format: "%8.2f", timeMs).padding(toLength: 12, withPad: " ", startingAt: 0)) │ \(String(format: "%8.3f", perRow).padding(toLength: 11, withPad: " ", startingAt: 0)) │ \(scaling.padding(toLength: 11, withPad: " ", startingAt: 0)) │")

            previousPerRow = perRow
        }

        print("└─────────┴──────────────┴─────────────┴─────────────┘")

        if results.count >= 2 {
            let (firstRows, firstTime) = results.first!
            let (lastRows, lastTime) = results.last!
            let scalingExponent = log(lastTime / firstTime) / log(Double(lastRows) / Double(firstRows))

            print("\nScaling exponent: \(String(format: "%.2f", scalingExponent))")
            print("  1.0 = O(n) ✅ linear")
            print("  2.0 = O(n²) ❌ quadratic")
        }
    }

    // MARK: - First Row Overhead

    @Test("First row overhead")
    func firstRowOverhead() {
        let tests: [(rows: Int, render: () -> Void)] = [
            (1, { render(SimpleTable10x1()) }),
            (2, { render(SimpleTable10x2()) }),
            (5, { render(SimpleTable10x5()) }),
            (10, { render(SimpleTable10x10()) }),
        ]

        var times: [(rows: Int, time: Double)] = []

        for test in tests {
            var totalTime: Double = 0
            for _ in 0..<20 {
                let start = ContinuousClock.now
                test.render()
                let elapsed = ContinuousClock.now - start
                totalTime += Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            }
            times.append((test.rows, totalTime / 20))
        }

        print("\n📊 First Row Overhead Analysis")
        let oneRowMs = times[0].time * 1000
        print("   1 row:  \(String(format: "%.2f", oneRowMs))ms")

        for (rows, time) in times.dropFirst() {
            let totalMs = time * 1000
            let incrementalMs = (time - times[0].time) * 1000 / Double(rows - 1)
            print("   \(rows) rows: \(String(format: "%.2f", totalMs))ms (incremental: \(String(format: "%.2f", incrementalMs))ms/row)")
        }

        if times.count >= 2 {
            let overhead = times[0].time / (times[1].time - times[0].time)
            print("\n   First row overhead: \(String(format: "%.1f", overhead))x vs subsequent rows")
        }
    }

    // MARK: - Span Overhead

    @Test("Span overhead comparison")
    func spanOverhead() {
        let iterations = 10

        func measure(_ block: () -> Void) -> Double {
            var total: Double = 0
            for _ in 0..<iterations {
                let start = ContinuousClock.now
                block()
                let elapsed = ContinuousClock.now - start
                total += Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            }
            return total / Double(iterations)
        }

        let simpleTime = measure { render(SimpleTable5x30()) }
        let rowspanTime = measure { render(RowspanTable30()) }
        let complexTime = measure { render(ComplexTable30()) }

        print("\n📊 Span Overhead (30 rows)")
        print("   Simple:   \(String(format: "%.2f", simpleTime * 1000))ms")
        print("   Rowspan:  \(String(format: "%.2f", rowspanTime * 1000))ms (\(String(format: "%.1f", rowspanTime / simpleTime))x)")
        print("   Complex:  \(String(format: "%.2f", complexTime * 1000))ms (\(String(format: "%.1f", complexTime / simpleTime))x)")
    }
}

// MARK: - Pre-defined Table Structures

// Simple tables with varying sizes
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

// Rowspan table (triggers Mirror reflection)
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

// Complex table with mixed spans
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
