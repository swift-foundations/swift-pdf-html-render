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

    /// Extract ABSOLUTE text positions per BT/ET block. Within a BT block,
    /// each `Td` is a relative shift from the previous start-of-line; this
    /// helper accumulates those shifts so each `(text) Tj` reports its real
    /// user-space coordinate. BT resets the accumulator to (0, 0).
    fileprivate func absoluteTjPositions() -> [(x: Double, y: Double, text: String)] {
        let s = String(decoding: self, as: UTF8.self)
        var out: [(Double, Double, String)] = []
        var x = 0.0, y = 0.0
        var inBT = false
        let tdRe = /^\s*(-?\d+\.?\d*)\s+(-?\d+\.?\d*)\s+Td\s*$/
        let tjRe = /^\s*\(([^)]*)\)\s*Tj\s*$/
        for rawLine in s.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line == "BT" { inBT = true; x = 0; y = 0; continue }
            if line == "ET" { inBT = false; continue }
            guard inBT else { continue }
            if let m = try? tdRe.wholeMatch(in: rawLine) {
                x += Double(m.output.1) ?? 0
                y += Double(m.output.2) ?? 0
                continue
            }
            if let m = try? tjRe.wholeMatch(in: rawLine) {
                out.append((x, y, String(m.output.1)))
            }
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

    // 6. Discriminating test for H1 (cell-layout primitive missing) vs H2
    //    (state-stack pop-ordering bug as invoice page-1 cause).
    //
    // After A.1'+A.3 landed, factuur-21 still has 3 pages and the Letter.Header
    // 2-col layout stacks vertically on page 1. Two hypotheses about the cause:
    //   H1 — cell horizontal-row layout primitive is missing
    //   H2 — state-stack pop-ordering bug between sibling tables corrupts layout
    //
    // This test renders an ISOLATED single 2-col table with explicit asymmetric
    // width hints. No sibling tables → state-stack pop-ordering is sidestepped.
    // If cells render side-by-side here, the cell-layout primitive IS present;
    // the invoice page-1 stacking is caused by sibling-table interactions (H2).
    // If cells stack vertically here, the primitive is missing (H1).
    //
    // Phase B scope decision is gated on this test's result.
    @Test
    func `discriminating: isolated 2-col table cells render side-by-side`() throws {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "ALPHA" }.css.width(.percent(60))
                        TableDataCell { "BETA" }.css.width(.percent(40))
                    }
                }
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { TestView() })
        let positions = bytes.tjPositions()
        let alpha = positions.first { $0.text.contains("ALPHA") }
        let beta = positions.first { $0.text.contains("BETA") }
        try #require(alpha != nil && beta != nil,
                     "Both ALPHA and BETA should appear in content stream")
        // Renderer emits ALPHA via absolute Tm, BETA via relative Td.
        // BETA's captured x is the offset from ALPHA's text origin (≈ LEFT
        // column width minus cellPadding). For 60/40 split on a4 content
        // width 451pt: LEFT column ≈ 271pt → BETA's relative x ≈ 270.
        // For stacked layout (H1), both texts share the same absolute X,
        // making BETA's relative x ≈ 0.
        //
        // Discriminating threshold: BETA.x > 50pt = clearly horizontal layout.
        #expect(beta!.x > 50,
                "Discriminating test: BETA's relative x-offset from ALPHA (\(beta!.x)) should be > 50pt if cells are side-by-side (case A → H2 confirmed); near 0 if vertically stacked (case B → H1 confirmed). ALPHA pos = (\(alpha!.x), \(alpha!.y)); BETA pos = (\(beta!.x), \(beta!.y)).")
    }

    // 7. CSS `white-space: nowrap` suppresses line-wrap on overflow (A.4)
    //
    // Renders the same long line — clearly wider than a4 content width
    // (≈ 451pt at default margins) — twice: once under default
    // `white-space: normal`, once under `.nowrap`.
    //
    // Empirically, the renderer emits one `BT` block with words separated
    // by `dx 0 Td` (relative move along same baseline). When wrap-on-
    // overflow triggers (default `.normal`), the next Td drops the line:
    // `−width(consumed) −lineHeight Td`. That NEGATIVE-Y Td is the
    // assertion-level signal of "wrap happened".
    //
    // .normal: at least one Td with y < 0 → wrap happened.
    // .nowrap: no Td has y < 0 → wrap-on-overflow was suppressed.
    //
    // This anchors A.4. The wrap-on-overflow primitive lives in
    // PDF.Context.Text.Run.render(into:) gated by `context.mode.noWrap`;
    // the HTML mapping is in
    // W3C_CSS_Text.WhiteSpace+PDF.HTML.Style.Modifier.swift.
    @Test
    func `white-space nowrap suppresses wrap-on-overflow line-breaks`() throws {
        struct WideText: HTML.View {
            let nowrap: Bool
            var body: some HTML.View {
                Paragraph {
                    "Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
                }
                .css.whiteSpace(nowrap ? .nowrap : .normal)
            }
        }
        let normalBytes = pageBytes(PDF.HTML.pages { WideText(nowrap: false) })
        let nowrapBytes = pageBytes(PDF.HTML.pages { WideText(nowrap: true) })
        let normalLineBreaks = normalBytes.tjPositions().filter { $0.y < 0 }.count
        let nowrapLineBreaks = nowrapBytes.tjPositions().filter { $0.y < 0 }.count
        #expect(normalLineBreaks > 0,
                "Long text under .normal should wrap (at least one Td with y < 0); got \(normalLineBreaks)")
        #expect(nowrapLineBreaks == 0,
                "Long text under .nowrap should NOT wrap (no Td with y < 0); got \(nowrapLineBreaks)")
    }

    // 5. State-stack pop-ordering bug reproducer (γ-5 trigger v)
    //
    // Phase B reproducer. Two sibling top-level `<table>` elements, each
    // a 60/40 column split via `.css.width(.percent(60))` /
    // `.css.width(.percent(40))`. Per Test 6 (isolated), this allocation
    // is honored and the second cell's relative-Td x-offset is ~270pt
    // (well above the equal-width baseline of ~226pt).
    //
    // The state-stack hypothesis (per `Research/css-fidelity-gap-inventory.md`
    // §Addendum 2026-05-11): writes from Table 2's column-width modifiers
    // hit STALE state — either Table 1's `context.table.recording` (if
    // pops missed), or `context.table == nil` (if some other state
    // corruption), causing Table 2's column-width allocator to fall back
    // to equal-width OR to collapse columns into a single column.
    //
    // Discriminating assertions:
    //  • Both tables should produce a `B1` and `B2` Tj.
    //  • Both relative-Td x-offsets for B1 and B2 should exceed 50pt
    //    (clear evidence of horizontal cell layout in both tables).
    //  • The two offsets should be approximately equal (within 5pt) —
    //    proving the second table's allocator behaves identically to
    //    the first's.
    // 8. CSS `width: N%` per CSS 2.1 §10.3.4 / CSS Box Sizing 3 §6.3 is
    //    percentage of containing-block width. The renderer's
    //    `W3C_CSS_BoxModel.Width.apply` previously routed every
    //    `.lengthPercentage` form through the shared
    //    `PDF.UserSpace.Size(lp, currentSize:, baseFontSize:)` init, which
    //    resolves percentages against font size — correct for `font-size`
    //    and `line-height`, but wrong for layout-related properties.
    //
    //    For `.css.width(.percent(100))` on an outer `<table>` with 11pt
    //    default font, the old code yielded `constraint.width = 11pt`,
    //    collapsing the layout box to ~11pt wide; both cells then
    //    rendered overlapping at the left. This was the actual root cause
    //    of factuur-21's Letter.Header appearing as a vertical stack.
    //
    //    Fix: `.lengthPercentage(.percentage(p))` now uses
    //    `context.layout.box.width * p/100` as the percentage reference.
    //    Length forms (px, em, pt) continue through the existing path.
    @Test
    func `outer table css width(.percent(100)) does not collapse layout box`() throws {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "LEFT" }.css.width(.percent(100))
                        TableDataCell { "RIGHT" }
                    }
                }
                .css.width(.percent(100))
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { TestView() })
        let positions = bytes.tjPositions()
        let right = positions.first { $0.text.contains("RIGHT") }
        try #require(right != nil, "RIGHT should appear in content stream")
        // Without the fix: RIGHT.x ≈ 8pt (table collapsed to ~11pt wide).
        // With the fix: RIGHT.x should match A.1' regression (~300pt for
        // 67%/33% split of full a4 content width of 451pt).
        #expect(right!.x > 270,
                "Outer `<table>.css.width(.percent(100))` must NOT collapse the table to ~11pt; got RIGHT.x=\(right!.x)")
    }

    @Test
    func `sibling tables: second table column-width hints reach their state`() throws {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "A1" }.css.width(.percent(60))
                        TableDataCell { "B1" }.css.width(.percent(40))
                    }
                }
                Table {
                    TableRow {
                        TableDataCell { "A2" }.css.width(.percent(60))
                        TableDataCell { "B2" }.css.width(.percent(40))
                    }
                }
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { TestView() })
        let positions = bytes.tjPositions()
        let b1 = positions.first { $0.text.contains("B1") }
        let b2 = positions.first { $0.text.contains("B2") }
        try #require(b1 != nil, "Sibling 1: B1 should appear in content stream")
        try #require(b2 != nil, "Sibling 2: B2 should appear in content stream")
        #expect(b1!.x > 50,
                "Sibling 1 (no leakage source): B1 x-offset \(b1!.x) should exceed 50pt — confirms isolated column layout works")
        #expect(b2!.x > 50,
                "Sibling 2 (leakage target): B2 x-offset \(b2!.x) should exceed 50pt — if state-stack leaks, Table 2's width hints don't reach its allocator and B2 collapses near 0")
        #expect(abs(b1!.x - b2!.x) < 5,
                "Sibling tables 1 & 2 with identical width hints should yield identical column allocations; got B1.x=\(b1!.x), B2.x=\(b2!.x)")
    }

    /// Regression test for the void-element push/pop asymmetry bug
    /// (Phase B.2, 2026-05-12).
    ///
    /// Before the fix, `<br>` (a void element) would push without
    /// adding a scope to `elementStack` and without incrementing
    /// `Recording.elementDepth`, but its matching pop would
    /// unconditionally decrement both. In Letter.Recipient-shaped
    /// content (multiple `<br>` followed by an empty nested table in
    /// the left cell of a 2-cell layout), this caused
    /// `finalizeFirstRow` to fire prematurely mid-content, and the
    /// chain of corrupted scope-pops nilled `context.table` by the
    /// time the right cell pushed — so the right cell's `<h3>` would
    /// render at the bottom of the left cell's content, not at the
    /// top of the right cell.
    @Test
    func `Void elements before sibling cell do not nil context.table`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell {
                            HTML.Element.Tag(tag: "b") { "LBOLD" }
                            HTML.Element.Tag<Never>(tag: "br")
                            "L1"
                            HTML.Element.Tag<Never>(tag: "br")
                            "L2"
                            HTML.Element.Tag<Never>(tag: "br")
                            "L3"
                            HTML.Element.Tag<Never>(tag: "br")
                            "L4"
                            HTML.Element.Tag<Never>(tag: "br")
                            Table { TableRow { TableDataCell { "" }; TableDataCell { "" } } }
                        }.css.verticalAlign(.top).width(.percent(100))
                        TableDataCell {
                            HTML.Element.Tag(tag: "h3") { "HEADING" }
                        }.css.verticalAlign(.top)
                    }
                }
                .css.width(.percent(100))
                .borderCollapse(.collapse)
            }
        }
        // Use ABSOLUTE positions (accumulated Td shifts) since LBOLD and
        // HEADING share a BT block and HEADING's Td is relative to L4's
        // start-of-line, not to BT origin.
        let positions = pageBytes(PDF.HTML.pages { V() }).absoluteTjPositions()
        let lbold = positions.first { $0.text.contains("LBOLD") }
        let heading = positions.first { $0.text.contains("HEADING") }
        try #require(lbold != nil, "LBOLD must appear in content stream")
        try #require(heading != nil, "HEADING must appear in content stream")
        // h3 in right cell with vertical-align: top must render near
        // the top of the row — same absolute y as LBOLD (h3 is slightly
        // larger so baseline is a few pt below). Pre-fix bug placed
        // HEADING ~130pt below LBOLD.
        #expect(abs(lbold!.y - heading!.y) < 25,
                "h3 absolute y (\(heading!.y)) must align with top of right cell, near LBOLD (\(lbold!.y)) — pre-fix bug placed it ~130pt below")
        // Right column: HEADING.x must be greater than LBOLD.x by
        // roughly half the page width (two equal columns from
        // borderCollapse + width:100%).
        #expect(heading!.x > lbold!.x + 100,
                "h3 absolute x (\(heading!.x)) must render in right column, well right of LBOLD (\(lbold!.x))")
    }
}
