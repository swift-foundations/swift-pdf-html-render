// BaselineEmpiricalTests.swift
// Empirical anchor tests for claims used by Phase A / Phase B framing in
// HANDOFF-swift-pdf-render-parity.md Rev 7.1 Phase A.0 interlude.
//
// The tests parse PDF content streams to verify low-level behaviour:
//  1. Default cell vertical-align is top (anchors A.1 retargeting evidence).
//  2. `<td>.width(.percent(N))` yields proportional column allocation
//     (regression test for A.1' / commit c443ddf).
//  3. Default border-collapse mode IS .collapse (anchors A.2 framing).
//  4. Setting `Configuration.table.border.width = 0` produces zero strokes
//     (previews A.3's effect).
//  5. State-stack pop-ordering bug between sibling tables (γ-5 trigger v
//     reproducer; disabled until Phase B fix lands).

import Foundation
import Testing
import CSS
import HTML_Rendering
import PDF_Rendering

@testable import PDF_HTML_Rendering

// MARK: - Helpers (content-stream byte-level inspection)

extension Array where Element == UInt8 {
    /// Count stroke operators (` S\n`) in the content stream. Each
    /// `emit.line` call emits `... m\n... l\n... S\n`; counting `S` gives a
    /// stroke-per-line count.
    fileprivate func countStrokes() -> Int {
        let s = String(decoding: self, as: UTF8.self)
        return s.components(separatedBy: " S\n").count - 1
    }

    /// Extract Tj positions: (x, y, text) for each text-show in BT/ET
    /// blocks. The text-positioning operator `X Y Td` precedes `(text) Tj`.
    fileprivate func tjPositions() -> [(x: Double, y: Double, text: String)] {
        let s = String(decoding: self, as: UTF8.self)
        var out: [(Double, Double, String)] = []
        let re = /(?<x>-?\d+\.?\d*)\s+(?<y>-?\d+\.?\d*)\s+Td\s*\n?\s*\((?<text>[^)]*)\)\s*Tj/
        for m in s.matches(of: re) {
            let x = Double(m.output.x) ?? .nan
            let y = Double(m.output.y) ?? .nan
            out.append((x, y, String(m.output.text)))
        }
        return out
    }
}

private func pageBytes(_ pages: [PDF.Page]) -> [UInt8] {
    Array(pages.flatMap { $0.contents }.flatMap { $0.data })
}

// MARK: - Tests

@Suite
struct `Baseline Empirical Tests` {

    // 1. Default cell vertical-align IS top
    //
    // Asserts: cell content baseline Y is near the TOP of the cell content
    // area. For a single-cell single-row default-styled table on a4:
    //   expected baselineY (PDF Y-up) ≈ pageHeight - margin.top - padding - ascent
    //                                 ≈ 841.89 - 72 - 4 - 9 ≈ 757
    // Top-aligned: Y near 757. Middle/bottom-aligned would shift Y down for
    // a multi-row or taller cell. This test verifies the *single-cell*
    // baseline-vs-top distance is within expected ascent+padding range,
    // anchoring the default-is-top claim used in A.1's verification.
    @Test
    func `default cell content baseline is at top of cell padding-inset area`() throws {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "ANCHOR" }
                    }
                }
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { TestView() })
        let positions = bytes.tjPositions()
        let pos = positions.first { $0.text.contains("ANCHOR") }
        try #require(pos != nil, "ANCHOR text should appear in content stream")
        // Top-aligned: baselineY > 740 (near top). Bottom-aligned would be
        // smaller (text near bottom of cell). Middle-aligned would also be
        // smaller. The threshold of 740 is conservative — actual top-aligned
        // value is ~757; bottom-aligned for a one-row table would be ~720.
        #expect(pos!.y > 740,
                "Cell content baseline Y should be near top of page (top-aligned default); got y=\(pos!.y)")
    }

    // 2. A.1' column-width allocator honors <td>.width(.percent(N))
    //
    // Regression test for commit c443ddf. Without A.1', columns are
    // equal-width; with A.1', LEFT(width 100%) gets ~67% and RIGHT(auto)
    // gets ~33% of bounds.width.
    @Test
    func `td width percent 100 yields proportional column allocation`() throws {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "LEFT" }.css.width(.percent(100))
                        TableDataCell { "RIGHT" }
                    }
                }
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { TestView() })
        let positions = bytes.tjPositions()
        let leftPos = positions.first { $0.text.contains("LEFT") }
        let rightPos = positions.first { $0.text.contains("RIGHT") }
        try #require(leftPos != nil && rightPos != nil,
                     "Both LEFT and RIGHT should appear in content stream")
        // Renderer emits LEFT via absolute `Tm` (`76 744 Tm`) followed by a
        // RELATIVE `Td` for RIGHT (`relX 0 Td`) inside the same BT/ET block.
        // So RIGHT's captured x is a relative offset from LEFT's origin —
        // empirically the LEFT column width (cell width minus padding).
        //
        // a4 content width ≈ 451pt. Equal-width 2-cols → LEFT column ≈ 226pt,
        // so RIGHT's relative offset would be ≈ 226. Under A.1' weighted
        // allocation (weights [100, 50], sum=150) → LEFT column ≈ 67% × 451
        // ≈ 301pt, so RIGHT's relative offset is ≈ 300.
        //
        // Assert relative offset > 270pt: clearly past equal-width position.
        #expect(rightPos!.x > 270,
                "RIGHT column's relative x-offset from LEFT (\(rightPos!.x)) should exceed 270pt under A.1' weighted allocation; equal-width would give ~226pt")
    }

    // 3. Default border-collapse mode IS collapse
    //
    // 2×2 table with default border (width = 0.5pt). Counts stroke ops:
    // .collapse emits per-cell left+top + table-level right+bottom (≈ 10-12).
    // .separate would emit 4 edges per cell (16+).
    @Test
    func `default border-collapse draws shared cell edges (fewer strokes than separate)`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell { "A" }
                            TableDataCell { "B" }
                        }
                        TableRow {
                            TableDataCell { "C" }
                            TableDataCell { "D" }
                        }
                    }
                }
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { TestView() })
        let strokes = bytes.countStrokes()
        #expect(strokes < 14,
                "Default border-collapse mode should emit fewer strokes than .separate (16+); got \(strokes)")
    }

    // 4. Configuration.table.border.width = 0 produces NO border strokes
    //
    // Previews A.3's effect: with border width 0, default-styled tables
    // render borderless (matches W3C cascade default).
    @Test
    func `configuration with table border width 0 produces zero border strokes`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table {
                    TableBody {
                        TableRow {
                            TableDataCell { "X" }
                            TableDataCell { "Y" }
                        }
                        TableRow {
                            TableDataCell { "Z" }
                            TableDataCell { "W" }
                        }
                    }
                }
            }
        }
        var config = PDF.HTML.Configuration()
        config.table.border.width = 0
        let bytes = pageBytes(PDF.HTML.pages(configuration: config) { TestView() })
        let strokes = bytes.countStrokes()
        #expect(strokes == 0,
                "Setting table.border.width = 0 should suppress all border strokes; got \(strokes)")
    }

    // 5. State-stack pop-ordering bug reproducer placeholder (γ-5 trigger v)
    //
    // Currently a SHAPE placeholder: two sibling top-level tables render
    // without crash. Phase B's sub-investigation will author the proper
    // reproducer with CSS modifier on the second table whose write should
    // reach its state — and that fails today because the state-stack
    // pop-ordering defect lets the write go to a stale snapshot.
    //
    // Re-enable + replace assertion when Phase B's reproducer materialises.
    @Test(.disabled("γ-5 trigger v state-stack pop-ordering bug; precise reproducer TBD as part of Phase B sub-investigation"))
    func `sibling tables placeholder: both render without crash`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table { TableRow { TableDataCell { "FIRST" } } }
                Table { TableRow { TableDataCell { "SECOND" } } }
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { TestView() })
        let s = String(decoding: bytes, as: UTF8.self)
        #expect(s.contains("FIRST"))
        #expect(s.contains("SECOND"))
    }
}
