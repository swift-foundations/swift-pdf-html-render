// PDF.HTML.Context.Table.PendingCellBorder.swift
// Pending cell border drawn after content when actual row height is known

import Layout_Primitives

extension PDF.HTML.Context.Table {
    /// Pending cell borders to draw after content (so we know actual row height)
    public struct PendingCellBorder {
        let column: Int
        let colspan: Int
        let rowspan: Int
        let isHeader: Bool
        let textAlignment: Horizontal.Alignment
        /// Per-side border declarations captured on the cell scope via
        /// CSS modifiers (`border-bottom`, etc.). Rendered at row-pop time
        /// once the cell's bounds are finalized.
        let pendingBorderTop: PDF.HTML.Context.Element.Scope.PendingSideBorder?
        let pendingBorderRight: PDF.HTML.Context.Element.Scope.PendingSideBorder?
        let pendingBorderBottom: PDF.HTML.Context.Element.Scope.PendingSideBorder?
        let pendingBorderLeft: PDF.HTML.Context.Element.Scope.PendingSideBorder?

        init(
            column: Int,
            colspan: Int,
            rowspan: Int,
            isHeader: Bool,
            textAlignment: Horizontal.Alignment,
            pendingBorderTop: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil,
            pendingBorderRight: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil,
            pendingBorderBottom: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil,
            pendingBorderLeft: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil
        ) {
            self.column = column
            self.colspan = colspan
            self.rowspan = rowspan
            self.isHeader = isHeader
            self.textAlignment = textAlignment
            self.pendingBorderTop = pendingBorderTop
            self.pendingBorderRight = pendingBorderRight
            self.pendingBorderBottom = pendingBorderBottom
            self.pendingBorderLeft = pendingBorderLeft
        }
    }
}
