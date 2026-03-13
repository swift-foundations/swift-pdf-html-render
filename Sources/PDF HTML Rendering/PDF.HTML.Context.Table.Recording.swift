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
    struct Recording: @unchecked Sendable {
        /// Recorded commands to replay after column widths are computed.
        var commands: [Command] = []

        /// Y position saved before first-row traversal (restored before replay).
        let savedY: PDF.UserSpace.Y

        /// Element nesting depth within the recorded row.
        ///
        /// Incremented on `_pushElement` (non-void), decremented on `_popElement`.
        /// When depth goes below zero, the row's own pop has been reached.
        var elementDepth: Int = 0

        /// Grid column count accumulated from cell pushes (accounts for colspan).
        var columnCount: Int = 0

        /// Colspan value from most recent `setAttribute("colspan", ...)`.
        /// Consumed when a cell push is recorded, then reset to 1.
        var pendingColspan: Int = 1
    }
}
