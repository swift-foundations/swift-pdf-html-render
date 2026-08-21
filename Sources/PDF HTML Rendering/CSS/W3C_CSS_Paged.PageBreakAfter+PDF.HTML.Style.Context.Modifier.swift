import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Paged.PageBreakAfter: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        case .avoid:

            context.avoidPageBreakAfter = true

        case .always, .left, .right:

            context.forcePageBreakAfter = true

        case .auto, .global:
            break
        }
    }
}
