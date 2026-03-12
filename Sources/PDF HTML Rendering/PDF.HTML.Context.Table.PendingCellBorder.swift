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
    }
}
