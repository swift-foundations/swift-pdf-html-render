import PDF_Rendering

extension W3C_CSS_Fonts.FontWeight: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .bold, .bolder:
            context.style.font = context.style.font.bold

        case .number(let weight) where weight >= 600:
            context.style.font = context.style.font.bold

        case .normal, .lighter:

            break

        case .number:

            break

        case .global:

            break
        }
    }
}
