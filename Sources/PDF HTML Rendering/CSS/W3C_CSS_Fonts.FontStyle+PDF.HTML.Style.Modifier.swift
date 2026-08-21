import PDF_Rendering

extension W3C_CSS_Fonts.FontStyle: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .italic, .oblique, .obliqueAngle:
            context.style.font = context.style.font.italic

        case .normal:

            break

        case .global:

            break
        }
    }
}
