import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Paged.PageBreakBefore: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .always:

            guard !context.page.isEmpty else { break }
            context.page.new()

        case .auto, .avoid:
            break

        case .left, .right:
            guard !context.page.isEmpty else { break }
            context.page.new()

        case .global:
            break
        }
    }
}
