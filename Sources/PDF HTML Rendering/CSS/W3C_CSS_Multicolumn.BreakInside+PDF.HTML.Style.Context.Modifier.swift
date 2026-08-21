import PDF_Rendering

extension W3C_CSS_Multicolumn.BreakInside: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {

        case .avoid, .avoidPage:
            context.avoidPageBreakInside = true

        case .avoidColumn, .avoidRegion:
            break

        case .auto, .global:
            break
        }
    }
}
