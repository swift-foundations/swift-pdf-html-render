import PDF_Rendering

extension W3C_CSS_Paged.PageBreakInside: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        case .avoid:

            context.avoidPageBreakInside = true

        case .auto, .global:

            break
        }
    }
}
