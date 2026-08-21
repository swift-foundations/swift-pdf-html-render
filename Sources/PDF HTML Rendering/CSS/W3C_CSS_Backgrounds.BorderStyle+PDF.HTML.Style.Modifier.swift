public import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Backgrounds.BorderStyle: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        guard let topStyle else { return }

        guard topStyle == .none || topStyle == .hidden else { return }

        let zero = PDF.UserSpace.Size<1>(0)
        if context.table != nil {
            context.table?.borderWidth = zero
        } else {
            context.pendingTableBorderWidth = zero
        }
    }

    private var topStyle: W3C_CSS_Values.LineStyle? {
        switch self {
        case .all(let style),
            .verticalHorizontal(let style, _),
            .topHorizontalBottom(let style, _, _),
            .topRightBottomLeft(let style, _, _, _):
            return style

        case .global:
            return nil
        }
    }
}
