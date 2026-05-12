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

    /// C-11 reproducer (Phase D, 2026-05-12): nested-table mid-row page-break
    /// pushes subsequent block to a NEW page even when prior page has room.
    ///
    /// Bug shape observed in factuur-21 post-C-2: the Invoice's totals table
    /// (Invoice.swift:255-281, outer 2-col table containing nested 3-row
    /// totals) page-breaks mid-rows — first 2 totals rows fit on page 1,
    /// 3rd row (`Totaalbedrag`) goes to page 2. The following payment
    /// paragraph (`Wij verzoeken u...`) — which logically should fit on
    /// page 2 after the broken-table-end with ~680pt of free space —
    /// renders on page 3.
    ///
    /// Minimal reproducer: outer 1-row 2-cell table with a TALL nested
    /// inner table; the inner table's last row falls below page-1 boundary
    /// and goes to page 2; a `Paragraph` follows.
    ///
    /// Expected (correct): total 2 pages. The `AFTER_PAYMENT_MARKER`
    /// paragraph renders on page 2 right after the broken-table-end.
    /// Actual (bug present): total 3 pages. `AFTER_PAYMENT_MARKER` is on
    /// page 3 alone.
    ///
    /// Currently disabled until the fix lands; on enable, will lock the
    /// invariant via `pageCount == 2`.
    @Test
    func `C-11: nested-table mid-row break does not force next block to new page`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                // Filler: 28 rows × 22pt ≈ 616pt — leaves ~80pt on page 1 for
                // the totals table to partially break (2 of 3 inner rows fit
                // on page 1; 3rd row TOTALMARKER falls to page 2).
                Table {
                    TableRow { TableDataCell { "F01" }; TableDataCell { "v01" } }
                    TableRow { TableDataCell { "F02" }; TableDataCell { "v02" } }
                    TableRow { TableDataCell { "F03" }; TableDataCell { "v03" } }
                    TableRow { TableDataCell { "F04" }; TableDataCell { "v04" } }
                    TableRow { TableDataCell { "F05" }; TableDataCell { "v05" } }
                    TableRow { TableDataCell { "F06" }; TableDataCell { "v06" } }
                    TableRow { TableDataCell { "F07" }; TableDataCell { "v07" } }
                    TableRow { TableDataCell { "F08" }; TableDataCell { "v08" } }
                    TableRow { TableDataCell { "F09" }; TableDataCell { "v09" } }
                    TableRow { TableDataCell { "F10" }; TableDataCell { "v10" } }
                    TableRow { TableDataCell { "F11" }; TableDataCell { "v11" } }
                    TableRow { TableDataCell { "F12" }; TableDataCell { "v12" } }
                    TableRow { TableDataCell { "F13" }; TableDataCell { "v13" } }
                    TableRow { TableDataCell { "F14" }; TableDataCell { "v14" } }
                    TableRow { TableDataCell { "F15" }; TableDataCell { "v15" } }
                    TableRow { TableDataCell { "F16" }; TableDataCell { "v16" } }
                    TableRow { TableDataCell { "F17" }; TableDataCell { "v17" } }
                    TableRow { TableDataCell { "F18" }; TableDataCell { "v18" } }
                    TableRow { TableDataCell { "F19" }; TableDataCell { "v19" } }
                    TableRow { TableDataCell { "F20" }; TableDataCell { "v20" } }
                    TableRow { TableDataCell { "F21" }; TableDataCell { "v21" } }
                    TableRow { TableDataCell { "F22" }; TableDataCell { "v22" } }
                    TableRow { TableDataCell { "F23" }; TableDataCell { "v23" } }
                    TableRow { TableDataCell { "F24" }; TableDataCell { "v24" } }
                    TableRow { TableDataCell { "F25" }; TableDataCell { "v25" } }
                    TableRow { TableDataCell { "F26" }; TableDataCell { "v26" } }
                    TableRow { TableDataCell { "F27" }; TableDataCell { "v27" } }
                    TableRow { TableDataCell { "F28" }; TableDataCell { "v28" } }
                }
                HTML.Element.Tag<Never>(tag: "hr")
                // The totals table — outer 2-cell with nested 3-row inner.
                Table {
                    TableRow {
                        TableDataCell { HTML.Empty() }.css.width(.percent(100))
                        TableDataCell {
                            Table {
                                TableRow { TableDataCell { "Bedrag" }; TableDataCell { "€ 6000" } }
                                TableRow { TableDataCell { "BTW" }; TableDataCell { "€ 1260" } }
                                TableRow { TableDataCell { "TOTALMARKER" }; TableDataCell { "€ 7260" } }
                            }
                        }
                    }
                }.css.borderCollapse(.collapse)
                HTML.Element.Tag<Never>(tag: "br")
                HTML.Element.Tag<Never>(tag: "br")
                Paragraph { "AFTER_PAYMENT_MARKER" }
            }
        }
        // 72pt margins pin the original page-fill scenario: with 36pt
        // default margins (post-Path-B), the totals table fits entirely on
        // page 1 and the mid-row-break invariant is not exercised. The bug
        // this test locks against is layout-engine-specific and content-
        // independent — pinning margins preserves the assertion's reach.
        let config = PDF.HTML.Configuration(margins: .init(all: 72))
        let pages = PDF.HTML.pages(configuration: config) { V() }
        // Determine which page each marker lands on via per-page tjPositions.
        // The bug: pre-fix, AFTER_PAYMENT_MARKER lands on a new page beyond
        // where TOTALMARKER's row ended; post-fix, it lands on the same
        // page as TOTALMARKER (page 2 in this reproducer).
        var totalPage: Int?
        var afterPage: Int?
        for (i, page) in pages.enumerated() {
            let pb = Array(page.contents.flatMap { $0.data })
            let positions = pb.tjPositions()
            if positions.contains(where: { $0.text.contains("TOTALMARKER") }) {
                totalPage = i + 1
            }
            if positions.contains(where: { $0.text.contains("AFTER_PAYMENT_MARKER") }) {
                afterPage = i + 1
            }
        }
        try #require(totalPage != nil, "TOTALMARKER missing")
        try #require(afterPage != nil, "AFTER_PAYMENT_MARKER missing")
        #expect(afterPage! == totalPage!,
                "C-11: AFTER_PAYMENT_MARKER (page \(afterPage!)) must land on the same page where TOTALMARKER (page \(totalPage!)) ended; pre-fix bug forced it to a new page via stale rowStartY in popTableRow")
    }

    /// Regression test for the `constraint.width` scope-leak (Phase B.3,
    /// 2026-05-12).
    ///
    /// Before the fix, the Width modifier's `constraint.width` output
    /// was set but never cleared by `applyBoxModel`. Any descendant
    /// element's CSS-modifier dispatch (which re-runs `applyBoxModel`)
    /// re-applied the stale ancestor constraint, overwriting the
    /// descendant's correct `layout.box.urx` with `llx + ancestorWidth`.
    /// In Letter.Header-shaped content (factuur-21), an `h3` with its
    /// own margin/textAlign modifiers inside the sender cell pushed
    /// `urx` to `cellLlx + 451 = 827` — off-page (A4 width = 595.276).
    @Test
    func `Width constraint does not leak into descendant box-model resolution`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "LEFT" }
                            .css.verticalAlign(.top).width(.percent(100))
                        TableDataCell {
                            HTML.Element.Tag(tag: "h3") { "RIGHT" }
                                .css.margin(top: 0).margin(bottom: 0)
                                .textAlign(.right)
                        }.css.verticalAlign(.top)
                    }
                }
                .css.width(.percent(100))
                .borderCollapse(.collapse)
            }
        }
        let positions = pageBytes(PDF.HTML.pages { V() }).absoluteTjPositions()
        let right = positions.first { $0.text.contains("RIGHT") }
        try #require(right != nil, "RIGHT must appear in content stream")
        // A4 width = 595.276pt. Pre-fix bug placed RIGHT at x ≈ 719
        // (cell llx + leaked outer constraint.width = 376 + 451 = 827,
        // minus right-align trim).
        #expect(right!.x < 595,
                "RIGHT absolute x (\(right!.x)) must be on-page — pre-fix bug rendered descendants past A4 right edge due to constraint.width leak from outer .css.width(.percent(100)) ancestor")
        // Also assert RIGHT is in the actual right column (not collapsed
        // back to the left edge): it must be well right of the LEFT cell.
        let left = positions.first { $0.text.contains("LEFT") }
        try #require(left != nil, "LEFT must appear in content stream")
        #expect(right!.x > left!.x + 100,
                "RIGHT (\(right!.x)) must render in right column, well right of LEFT (\(left!.x))")
    }

    /// C-E1 reproducer (Phase E, 2026-05-12): nested 2-col table cells
    /// render on separate Y positions instead of side-by-side.
    ///
    /// Bug shape observed in factuur-21: Letter.Sender's inner table
    /// (rows of `<td>label</td><td>value</td>`) — placed in the RIGHT
    /// cell of the outer 2-column header table — renders each label and
    /// its value on separate Y positions instead of side-by-side. Affects
    /// tel / address / iban / kvk / btw / email / website pairs.
    ///
    /// Test 6 (`discriminating: isolated 2-col table cells render
    /// side-by-side`, line 232) confirmed isolated 2-col tables render
    /// correctly. The C-E1 hypothesis: the bug is specific to NESTED
    /// 2-col tables (a 2-col table inside a cell of another 2-col table).
    ///
    /// Minimal reproducer: outer 2-col table with simple LEFT cell content
    /// and an inner 2-col table in the RIGHT cell with two label/value
    /// rows. No additional styling (no padding/verticalAlign/textAlign on
    /// inner cells) — isolates the bug to nested-table layout, not
    /// modifier-dispatch interactions.
    ///
    /// Discriminating assertions (absolute-coordinate-extraction per
    /// Phase B.3 / HANDOFF-state-stack-pop-ordering.md):
    ///   - LABEL1 and VALUE1 share approximately the same Y (within 2pt)
    ///     → cells side-by-side in inner row 1.
    ///   - VALUE1.x > LABEL1.x + 30pt → clearly horizontal layout.
    ///   - Same for row 2 (LABEL2 / VALUE2).
    ///   - Row 2 Y < row 1 Y → inner rows correctly stack vertically.
    ///
    /// If this test FAILS (cells share X, differ in Y), the root cause is
    /// inside the nested-table layout pass and localize via instrumentation.
    /// If this test PASSES (cells side-by-side in synthetic), the
    /// factuur-21 defect has a different root cause — read
    /// Letter.Sender.swift's actual HTML tree and compare.
    @Test
    func `C-E1: nested 2-col table cells render side-by-side`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "OUTER_LEFT" }
                        TableDataCell {
                            Table {
                                TableRow {
                                    TableDataCell { "LABEL1" }
                                    TableDataCell { "VALUE1" }
                                }
                                TableRow {
                                    TableDataCell { "LABEL2" }
                                    TableDataCell { "VALUE2" }
                                }
                            }
                        }
                    }
                }
                .css.borderCollapse(.collapse)
            }
        }
        let positions = pageBytes(PDF.HTML.pages { V() }).absoluteTjPositions()
        let label1 = positions.first { $0.text.contains("LABEL1") }
        let value1 = positions.first { $0.text.contains("VALUE1") }
        let label2 = positions.first { $0.text.contains("LABEL2") }
        let value2 = positions.first { $0.text.contains("VALUE2") }
        try #require(label1 != nil, "LABEL1 must appear in content stream")
        try #require(value1 != nil, "VALUE1 must appear in content stream")
        try #require(label2 != nil, "LABEL2 must appear in content stream")
        try #require(value2 != nil, "VALUE2 must appear in content stream")
        // Row 1: side-by-side
        #expect(abs(label1!.y - value1!.y) < 2,
                "C-E1 row 1: LABEL1.y (\(label1!.y)) and VALUE1.y (\(value1!.y)) must share the same baseline (Δy < 2pt). If Δy is large, the bug stacks cells vertically inside nested tables.")
        #expect(value1!.x > label1!.x + 30,
                "C-E1 row 1: VALUE1.x (\(value1!.x)) must be well right of LABEL1.x (\(label1!.x)) — clear horizontal layout (Δx > 30pt). If Δx ~ 0, cells collapsed to a single column.")
        // Row 2: side-by-side
        #expect(abs(label2!.y - value2!.y) < 2,
                "C-E1 row 2: LABEL2.y (\(label2!.y)) and VALUE2.y (\(value2!.y)) must share the same baseline (Δy < 2pt).")
        #expect(value2!.x > label2!.x + 30,
                "C-E1 row 2: VALUE2.x (\(value2!.x)) must be well right of LABEL2.x (\(label2!.x)) — Δx > 30pt.")
        // Inner rows stack vertically (row 1 above row 2)
        #expect(label1!.y > label2!.y,
                "C-E1 inner-row ordering: row 1 baseline (\(label1!.y)) must be above row 2 baseline (\(label2!.y)).")
    }

    /// C-E2 reproducer (Phase E, 2026-05-12): row-height anomaly in
    /// inner-table rows when value cell contains internal whitespace.
    ///
    /// Empirical bbox extraction on factuur-21 shows inner-table label/value
    /// pairs ARE side-by-side (C-E1 falsified) but row gaps are anomalously
    /// inflated when the value contains whitespace:
    ///
    ///   tel    +31 6 43 90 14 29        ← row N (value has internal spaces)
    ///                                     gap = 35.6pt (anomalous, +14pt)
    ///   email  info@tenthijeboonkkamp.nl ← row N+1 (no spaces)
    ///                                     gap = 21.8pt (normal)
    ///   website tenthijeboonkkamp.nl    ← row N+2
    ///                                     gap = 21.8pt (normal)
    ///
    /// Same pattern observed: Verzonden→Inkoopordernummer (long
    /// space-separated email list value) shows same anomaly.
    ///
    /// Hypothesis: the renderer's cell-content height accounting reserves
    /// space assuming a wrap *might* happen at internal whitespace tokens,
    /// inflating `cellContentHeight` past the actually-rendered 1-line
    /// visible content. The inflated height becomes `actualRowHeight`
    /// via `maxCellHeightInCurrentRow` and pushes the following row down.
    ///
    /// Locus candidates per popTableCell at
    /// PDF.HTML.Context+Rendering.swift:1189-1225:
    ///   cellContentHeight = (lly - tableCtx.bounds.lly) + padding.height
    /// If `lly` advance overshoots the rendered content (e.g., reserved
    /// 2 lines but rendered 1), the row over-reserves vertical space.
    ///
    /// Discriminating assertion: in a synthetic 3-row inner table where
    /// row 1's value contains internal whitespace and rows 2-3 do not,
    /// row-1→row-2 gap should equal row-2→row-3 gap (both single-line
    /// visible content). If row-1→row-2 is significantly larger, the
    /// anomaly is reproducible and localizable.
    @Test
    func `C-E2: row height stable across rows with same visible content shape`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "OUTER_LEFT" }.css.verticalAlign(.top)
                        TableDataCell {
                            Table {
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "L1" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "alpha beta gamma delta" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "L2" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "no-spaces-here" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "L3" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "still-no-spaces" } }
                                }
                            }
                            .css.borderCollapse(.collapse)
                        }.css.verticalAlign(.top)
                    }
                }
                .css.borderCollapse(.collapse).width(.percent(100))
            }
        }
        let positions = pageBytes(PDF.HTML.pages { V() }).absoluteTjPositions()
        let l1 = positions.first { $0.text == "L1" }
        let l2 = positions.first { $0.text == "L2" }
        let l3 = positions.first { $0.text == "L3" }
        try #require(l1 != nil, "L1 must appear in content stream")
        try #require(l2 != nil, "L2 must appear in content stream")
        try #require(l3 != nil, "L3 must appear in content stream")
        // Y decreases as we go down the page (per absoluteTjPositions
        // tracking — Td shifts are relative; cumulative Y reflects user
        // space). gap = positive when row N is above row N+1.
        let gap12 = abs(l1!.y - l2!.y)
        let gap23 = abs(l2!.y - l3!.y)
        // Diagnostic output: print exact gaps so the failure message shows
        // empirical evidence of the anomaly directly.
        #expect(abs(gap12 - gap23) < 3,
                "C-E2: row 1→2 gap (\(gap12)) should equal row 2→3 gap (\(gap23)) — both rows have single-line visible content. Δ > 3pt indicates value-with-whitespace inflates row height (factuur-21 anomaly reproduced). Pos: L1=(\(l1!.x),\(l1!.y)) L2=(\(l2!.x),\(l2!.y)) L3=(\(l3!.x),\(l3!.y)).")
    }

    /// C-E3 reproducer (Phase E, 2026-05-12): Variant adding Letter.Sender's
    /// first-row structure (address column with `<small>line</small><br>`
    /// pattern) before the metadata rows. Tests whether the multi-line
    /// address row's trailing `<br>` (which the renderer documents as a
    /// "1 line advance") leaks state that inflates the FIRST metadata row's
    /// computed height.
    ///
    /// Empirical anchor (factuur-21 bbox extraction):
    ///   address row spans y=123→187 (3 small lines + trailing br advance)
    ///   row 2 (tel)     y=200, yMax=209  (1 visible line)
    ///   row 3 (email)   y=235.6           ← GAP 26.6pt below row 2's yMax
    ///   row 4 (website) y=257.4           ← gap 13pt (normal)
    ///   row 5 (kvk)     y=279.2           ← gap 13pt
    /// The anomaly: row 2 → row 3 = 26.6pt (14pt extra); subsequent
    /// rows = 13pt (normal).
    ///
    /// If this test reproduces the anomaly (row1→row2 normal, row2→row3
    /// >> row3→row4), the trigger is the transition from address-row to
    /// metadata-rows. If it does NOT reproduce, the trigger is something
    /// else (h3 before table, or HTML.AnyView wrapping).
    @Test
    func `C-E3: row height stable after preceding multi-line br-stack row`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "OUTER_LEFT" }.css.verticalAlign(.top)
                        TableDataCell {
                            Table {
                                // Address-like row: empty + multi-line small/br stack
                                TableRow {
                                    TableDataCell { HTML.Empty() }
                                    TableDataCell {
                                        HTML.Element.Tag(tag: "small") { "ADDR1" }
                                        HTML.Element.Tag<Never>(tag: "br")
                                        HTML.Element.Tag(tag: "small") { "ADDR2" }
                                        HTML.Element.Tag<Never>(tag: "br")
                                        HTML.Element.Tag(tag: "small") { "ADDR3" }
                                        HTML.Element.Tag<Never>(tag: "br")
                                    }
                                }
                                // Metadata rows
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M1" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "value one two three" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M2" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "nospaces-here" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M3" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "anothernospaces" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M4" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "fourthrow" } }
                                }
                            }
                            .css.borderCollapse(.collapse)
                        }.css.verticalAlign(.top)
                    }
                }
                .css.borderCollapse(.collapse).width(.percent(100))
            }
        }
        let positions = pageBytes(PDF.HTML.pages { V() }).absoluteTjPositions()
        let m1 = positions.first { $0.text == "M1" }
        let m2 = positions.first { $0.text == "M2" }
        let m3 = positions.first { $0.text == "M3" }
        let m4 = positions.first { $0.text == "M4" }
        try #require(m1 != nil, "M1 must appear")
        try #require(m2 != nil, "M2 must appear")
        try #require(m3 != nil, "M3 must appear")
        try #require(m4 != nil, "M4 must appear")
        let gap12 = abs(m1!.y - m2!.y)
        let gap23 = abs(m2!.y - m3!.y)
        let gap34 = abs(m3!.y - m4!.y)
        // All metadata rows have single-line visible content. Gaps should be uniform.
        // The factuur-21 anomaly: gap12 is anomalously large vs gap23 / gap34.
        #expect(abs(gap12 - gap23) < 3,
                "C-E3: row 1→2 gap (\(gap12)) vs row 2→3 gap (\(gap23)). Δ > 3 means the first metadata row inherits extra height — anomaly reproduced. M1=(\(m1!.x),\(m1!.y)) M2=(\(m2!.x),\(m2!.y)) M3=(\(m3!.x),\(m3!.y)) M4=(\(m4!.x),\(m4!.y)).")
        #expect(abs(gap23 - gap34) < 3,
                "C-E3: row 2→3 gap (\(gap23)) vs row 3→4 gap (\(gap34)) should match.")
    }

    /// C-E4 reproducer (Phase E, 2026-05-12): exact replica of Letter.Header
    /// + Letter.Sender shape used in factuur-21:
    ///   - Outer table .css.width(.percent(100)).borderCollapse(.collapse)
    ///     - LEFT cell .css.verticalAlign(.top).width(.percent(100)) — recipient
    ///     - RIGHT cell .css.verticalAlign(.top) — sender, containing:
    ///       - h3 .css.margin(top: 0).margin(bottom: 0).textAlign(.right)
    ///       - Inner table .css.borderCollapse(.collapse) with:
    ///         - Address row (empty + small/br stack)
    ///         - Metadata rows (label/value with small + CSS)
    ///
    /// Variant D adds (vs C-E3):
    ///   - .width(.percent(100)) on the LEFT cell of the OUTER table
    ///   - h3 BEFORE the inner table inside the RIGHT cell
    ///
    /// If this test reproduces the factuur-21 anomaly (gap M1→M2 >> M2→M3),
    /// the localizing feature(s) are one of: outer LEFT cell's width(100%),
    /// the h3-before-inner-table, or their combination.
    @Test
    func `C-E4: Letter.Header + Letter.Sender exact-shape replica`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                Table {
                    TableRow {
                        TableDataCell { "RECIPIENT" }
                            .css.verticalAlign(.top).width(.percent(100))
                        TableDataCell {
                            HTML.Element.Tag(tag: "h3") { "SENDER_NAME" }
                                .css.margin(top: 0).margin(bottom: 0).textAlign(.right)
                            Table {
                                TableRow {
                                    TableDataCell { HTML.Empty() }
                                    TableDataCell {
                                        HTML.Element.Tag(tag: "small") { "ADDR1" }
                                        HTML.Element.Tag<Never>(tag: "br")
                                        HTML.Element.Tag(tag: "small") { "ADDR2" }
                                        HTML.Element.Tag<Never>(tag: "br")
                                        HTML.Element.Tag(tag: "small") { "ADDR3" }
                                        HTML.Element.Tag<Never>(tag: "br")
                                    }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M1" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "v one two three" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M2" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "nospaces" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M3" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "anothernospaces" } }
                                }
                                TableRow {
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "M4" } }
                                        .css.textAlign(.right).verticalAlign(.top).padding(right: .px(10))
                                    TableDataCell { HTML.Element.Tag(tag: "small") { "fourthrow" } }
                                }
                            }
                            .css.borderCollapse(.collapse)
                        }.css.verticalAlign(.top)
                    }
                }
                .css.width(.percent(100)).borderCollapse(.collapse)
            }
        }
        let positions = pageBytes(PDF.HTML.pages { V() }).absoluteTjPositions()
        let m1 = positions.first { $0.text == "M1" }
        let m2 = positions.first { $0.text == "M2" }
        let m3 = positions.first { $0.text == "M3" }
        let m4 = positions.first { $0.text == "M4" }
        try #require(m1 != nil, "M1 must appear")
        try #require(m2 != nil, "M2 must appear")
        try #require(m3 != nil, "M3 must appear")
        try #require(m4 != nil, "M4 must appear")
        let gap12 = abs(m1!.y - m2!.y)
        let gap23 = abs(m2!.y - m3!.y)
        let gap34 = abs(m3!.y - m4!.y)
        #expect(abs(gap12 - gap23) < 3,
                "C-E4: row M1→M2 gap (\(gap12)) vs M2→M3 gap (\(gap23)). Δ > 3 means factuur-21 anomaly reproduced in synthetic Letter.Header+Letter.Sender shape. M1=(\(m1!.x),\(m1!.y)) M2=(\(m2!.x),\(m2!.y)) M3=(\(m3!.x),\(m3!.y)) M4=(\(m4!.x),\(m4!.y)).")
        #expect(abs(gap23 - gap34) < 3,
                "C-E4: row M2→M3 gap (\(gap23)) vs M3→M4 gap (\(gap34)) should match.")
    }

    /// C-E5 reproducer (Phase E Round 3, 2026-05-12): paragraph wrap
    /// REGRESSES when a child element uses `.css.whiteSpace(.nowrap)`.
    ///
    /// Bug shape observed in factuur-21 payment paragraph (Invoice.swift:286
    /// onwards): the paragraph contains `HTML.Text(sender.iban).css.whiteSpace(.nowrap)`
    /// among normally-wrapping siblings. Empirically the entire paragraph
    /// renders as a single line extending past `bounds.width`, suggesting
    /// the mode.noWrap mutation set during the IBAN child's inlineStyle
    /// application is not restored after the IBAN's text emits, leaking
    /// the nowrap mode onto subsequent siblings AND/OR onto the flush
    /// of pre-IBAN runs.
    @Test
    func `C-E5: paragraph wraps despite nowrap child in middle`() throws {
        struct V: HTML.View {
            var body: some HTML.View {
                Paragraph {
                    "Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. "
                    HTML.Text("NOWRAP_TOKEN").css.whiteSpace(.nowrap)
                    " Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
                }
            }
        }
        let bytes = pageBytes(PDF.HTML.pages { V() })
        let lineBreaks = bytes.tjPositions().filter { $0.y < 0 }.count
        #expect(lineBreaks >= 2,
                "Paragraph with nowrap child in middle must still wrap at line boundaries; got \(lineBreaks) line-breaks (Tj with y<0). The nowrap child's mode mutation should be scoped to the child, not leak to the whole paragraph.")
    }
}
