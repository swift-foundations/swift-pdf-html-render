public import CSS_HTML_Rendering
public import PDF_Rendering
import PDF_Standard
import W3C_CSS_Values

extension W3C_CSS_Backgrounds.BorderBottom: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        guard case .properties(let properties) = self else { return }

        let style = properties.style ?? .none
        guard style != .none, style != .hidden else { return }

        let baseFontSize = context.configuration.defaultFontSize
        let currentSize = context.pdf.style.fontSize

        guard
            let width = properties.width.flatMap({
                pdfBorderWidth(
                    from: $0,
                    currentSize: currentSize,
                    baseFontSize: baseFontSize
                )
            }), width != PDF.UserSpace.Size<1>(0)
        else { return }

        guard let cssColor = properties.color,
            let pdfColor = PDF.Color(cssColor)
        else { return }

        context.pendingSideBorderBottom = .init(
            width: width,
            style: style,
            color: pdfColor
        )
    }
}

extension RawProperty: PDF.HTML.Style.Context.Modifier
where PropertyType: BorderSideProperty {
    public func apply(to context: inout PDF.HTML.Context) {
        let parts = parseBorderShorthand(self.value)
        PropertyType.applyParsedShorthand(
            width: parts.width,
            style: parts.style,
            color: parts.color,
            to: &context
        )
    }
}
