import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Text.WhiteSpace: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {

        switch self {
        case .normal:
            context.mode.preserveWhitespace = false
            context.mode.noWrap = false

        case .nowrap:
            context.mode.preserveWhitespace = false
            context.mode.noWrap = true

        case .pre:
            context.mode.preserveWhitespace = true
            context.mode.noWrap = true

        case .preWrap, .breakSpaces:
            context.mode.preserveWhitespace = true
            context.mode.noWrap = false

        case .preLine:
            context.mode.preserveWhitespace = false
            context.mode.noWrap = false

        case .global:
            break
        }
    }
}
