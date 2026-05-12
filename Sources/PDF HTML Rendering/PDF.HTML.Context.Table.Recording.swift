// PDF.HTML.Context.Table.Recording.swift
// Command recording for first-row column measurement

import PDF_Rendering

extension PDF.HTML.Context.Table {
    /// Records rendering commands during first-row traversal for column measurement.
    ///
    /// In push/pop architecture, the view tree is traversed exactly once.
    /// To measure column count before positioning cells, the first row's
    /// commands are recorded (not executed), column widths are computed,
    /// then the commands are replayed with correct layout.
    // WHY: Category D — structural Sendable workaround.
    // WHY: Contains [Command] where Command has `inlineStyle(Any)` case.
    // WHY: Recording is temporary and does not cross concurrency boundaries.
    // WHEN TO REMOVE: When Command drops the Any existential case.
    // TRACKING: unsafe-audit-findings.md Category D; SP-7.
    struct Recording: @unchecked Sendable {
        /// Recorded commands to replay after column widths are computed.
        var commands: [Command] = []

        /// Y position saved before first-row traversal (restored before replay).
        let savedY: PDF.UserSpace.Y

        /// Element nesting depth within the recorded row.
        ///
        /// Incremented on `_pushElement` (non-void), decremented on
        /// `_popElement` (non-void via `pushedIsVoid` peek). When depth
        /// goes below zero, the row's own pop has been reached.
        var elementDepth: Int = 0

        /// Stack of `isVoid` flags mirroring pushed elements within the
        /// recorded row. Used to keep `elementDepth` bookkeeping symmetric:
        /// void pushes don't increment depth, so their matching pops must
        /// not decrement it either.
        var pushedIsVoid: [Bool] = []

        /// Grid column count accumulated from cell pushes (accounts for colspan).
        var columnCount: Int = 0

        /// Colspan value from most recent `setAttribute("colspan", ...)`.
        /// Consumed when a cell push is recorded, then reset to 1.
        var pendingColspan: Int = 1

        /// Pending per-cell width hint (in percent) buffered from a recorded
        /// `<td>.css.width(.percent(N))` inlineStyle. Consumed at the next
        /// `_pushElement("td"/"th")` at recording depth 0, then cleared.
        var pendingCellWidthPercent: Double?

        /// Column index → width-weight hints collected during recording. Used
        /// by `finalizeFirstRow` to allocate proportional column widths.
        var columnWidthWeights: [Int: Double] = [:]

        /// Round 2b.1 (C-1 measurement): per-column min/max content widths
        /// captured during first-row recording. Read by allocator in
        /// Round 2b.2; ignored in Round 2b.1 (no behavior change invariant).
        /// min-content (W3C CSS Box Sizing 3 §4.1): widest unbreakable token
        /// per cell. max-content: sum of token + space widths per cell
        /// (single-line interpretation per orchestrator design; br handling
        /// deferred to Round 2b.2).
        var columnMinContentWidths: [Int: PDF.UserSpace.Width] = [:]
        var columnMaxContentWidths: [Int: PDF.UserSpace.Width] = [:]

        /// Round 2b.1: per-cell accumulators reset on each cell push,
        /// finalized into columnMin/MaxContentWidths on cell pop.
        var currentCellColumn: Int? = nil
        var currentCellMinWidth: PDF.UserSpace.Width = .init(0)
        var currentCellMaxWidth: PDF.UserSpace.Width = .init(0)

        /// Per-logical-line accumulator for max-content measurement.
        ///
        /// W3C CSS Box Sizing 3 §4.1: max-content of a box equals the
        /// narrowest size the box could take without overflowing its
        /// contents if no soft wraps occurred — for a cell containing a
        /// nested table, that is MAX of nested row widths, NOT SUM. Text
        /// runs append here; line-boundary events (`<br>`, nested `<tr>`
        /// push, cell pop) take MAX into `currentCellMaxWidth` and reset.
        var currentLineWidth: PDF.UserSpace.Width = .init(0)
    }
}
