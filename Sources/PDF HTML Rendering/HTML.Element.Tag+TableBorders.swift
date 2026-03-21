// HTML.Element.Tag+TableBorders.swift
// Table border and background drawing helpers

import HTML_Rendering_Core
import PDF_Rendering

extension HTML.Element.Tag {
    /// Draw cell border (only left and top edges to avoid double borders)
    ///
    /// Uses border-collapse approach: each cell draws its left and top borders.
    /// The table's right and bottom edges are drawn once at the end.
    static func drawCellBorder(
        bounds: PDF.UserSpace.Rectangle,
        tableCtx: PDF.HTML.Context.Table,
        context: inout PDF.HTML.Context
    ) {
        let color = tableCtx.borderColor
        let width = tableCtx.borderWidth.width
        guard tableCtx.borderWidth != .init(0) else { return }

        // Draw left edge (from lower-left to upper-left)
        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
            to: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.ury),
            color: color,
            width: width
        )

        // Draw top edge (from lower-left to lower-right)
        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
            to: PDF.UserSpace.Coordinate(x: bounds.urx, y: bounds.lly),
            color: color,
            width: width
        )
    }

    /// Draw right and bottom borders for a table fragment (per-page section)
    ///
    /// For multi-page tables, this is called:
    /// 1. Before each page break (to close the fragment on the current page)
    /// 2. At the end of the table (to close the final fragment)
    static func drawFragmentRightAndBottomBorders(
        tableCtx: PDF.HTML.Context.Table,
        fragmentStartY: PDF.UserSpace.Y,
        fragmentEndY: PDF.UserSpace.Y,
        context: inout PDF.HTML.Context
    ) {
        guard tableCtx.columnWidths.count > 0 else { return }

        let color = tableCtx.borderColor
        let width = tableCtx.borderWidth.width
        guard tableCtx.borderWidth != .init(0) else { return }
        let tableBounds = tableCtx.bounds

        // Draw right edge (from fragment top to fragment bottom)
        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentStartY),
            to: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentEndY),
            color: color,
            width: width
        )

        // Draw bottom edge (from table left to table right)
        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: tableBounds.llx, y: fragmentEndY),
            to: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentEndY),
            color: color,
            width: width
        )
    }

    /// Draw the table's right and bottom borders (completing the border-collapse grid)
    /// Convenience wrapper that uses the current fragment tracking properties.
    static func drawTableRightAndBottomBorders(
        tableCtx: PDF.HTML.Context.Table,
        context: inout PDF.HTML.Context
    ) {
        drawFragmentRightAndBottomBorders(
            tableCtx: tableCtx,
            fragmentStartY: tableCtx.currentFragmentStartY,
            fragmentEndY: tableCtx.currentFragmentEndY,
            context: &context
        )
    }

    /// Draw cell background (inset by half border width to avoid overlap)
    static func drawCellBackground(
        bounds: PDF.UserSpace.Rectangle,
        color: PDF.Color,
        borderWidth: PDF.UserSpace.Size<1> = 0,
        context: inout PDF.HTML.Context
    ) {
        // Inset by half the border width so border covers background edge cleanly
        let insetX = borderWidth.width / 2
        let insetY = borderWidth.height / 2
        context.pdf.emit.rectangle(
            bounds.insetBy(dx: insetX, dy: insetY),
            fill: color,
            stroke: nil
        )
    }
}
