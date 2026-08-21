import PDF_Rendering

extension W3C_CSS_Multicolumn.BreakAfter: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {

        case .avoid, .avoidPage:
            context.avoidPageBreakAfter = true

        case .always, .all, .page, .left, .right, .recto, .verso:
            context.forcePageBreakAfter = true

        case .avoidColumn, .column, .avoidRegion, .region:
            break

        case .auto, .global:
            break
        }
    }
}
