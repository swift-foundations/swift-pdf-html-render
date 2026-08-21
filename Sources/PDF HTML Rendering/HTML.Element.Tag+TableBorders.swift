import HTML_Rendering_Core
import PDF_Rendering

extension HTML.Tag.Element {

    static func drawCellBorder(
        bounds: PDF.UserSpace.Rectangle,
        tableCtx: PDF.HTML.Context.Table,
        context: inout PDF.HTML.Context
    ) {
        let color = tableCtx.borderColor
        let width = tableCtx.borderWidth.width
        guard tableCtx.borderWidth != .init(0) else { return }

        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
            to: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.ury),
            color: color,
            width: width
        )

        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
            to: PDF.UserSpace.Coordinate(x: bounds.urx, y: bounds.lly),
            color: color,
            width: width
        )
    }

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

        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentStartY),
            to: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentEndY),
            color: color,
            width: width
        )

        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: tableBounds.llx, y: fragmentEndY),
            to: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentEndY),
            color: color,
            width: width
        )
    }

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

    static func drawHorizontalBorder(
        from: PDF.UserSpace.Coordinate,
        to: PDF.UserSpace.Coordinate,
        color: PDF.Color,
        width: PDF.UserSpace.Width,
        style: W3C_CSS_Values.LineStyle,
        context: inout PDF.HTML.Context
    ) {
        switch style {
        case .double:
            let third = width / 3
            let offsetY = third.retag(Extent.Y<UserSpace>.self)
            let topY = from.y - offsetY
            let bottomY = from.y + offsetY
            context.pdf.emit.line(
                from: PDF.UserSpace.Coordinate(x: from.x, y: topY),
                to: PDF.UserSpace.Coordinate(x: to.x, y: topY),
                color: color,
                width: third
            )
            context.pdf.emit.line(
                from: PDF.UserSpace.Coordinate(x: from.x, y: bottomY),
                to: PDF.UserSpace.Coordinate(x: to.x, y: bottomY),
                color: color,
                width: third
            )

        default:
            context.pdf.emit.line(from: from, to: to, color: color, width: width)
        }
    }

    static func drawVerticalBorder(
        from: PDF.UserSpace.Coordinate,
        to: PDF.UserSpace.Coordinate,
        color: PDF.Color,
        width: PDF.UserSpace.Width,
        style: W3C_CSS_Values.LineStyle,
        context: inout PDF.HTML.Context
    ) {
        switch style {
        case .double:
            let third = width / 3
            let leftX = from.x - third
            let rightX = from.x + third
            context.pdf.emit.line(
                from: PDF.UserSpace.Coordinate(x: leftX, y: from.y),
                to: PDF.UserSpace.Coordinate(x: leftX, y: to.y),
                color: color,
                width: third
            )
            context.pdf.emit.line(
                from: PDF.UserSpace.Coordinate(x: rightX, y: from.y),
                to: PDF.UserSpace.Coordinate(x: rightX, y: to.y),
                color: color,
                width: third
            )

        default:
            context.pdf.emit.line(from: from, to: to, color: color, width: width)
        }
    }

    static func drawCellBackground(
        bounds: PDF.UserSpace.Rectangle,
        color: PDF.Color,
        borderWidth: PDF.UserSpace.Size<1> = 0,
        context: inout PDF.HTML.Context
    ) {

        let insetX = borderWidth.width / 2
        let insetY = borderWidth.height / 2
        context.pdf.emit.rectangle(
            bounds.insetBy(dx: insetX, dy: insetY),
            fill: color,
            stroke: nil
        )
    }
}
