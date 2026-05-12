// W3C_CSS_Backgrounds.BorderTop+PDF.HTML.Style.Modifier.swift
// CSS border-top property to PDF context translation.

public import PDF_Rendering
import PDF_Standard
import W3C_CSS_Values

extension W3C_CSS_Backgrounds.BorderTop: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        guard case .properties(let properties) = self else { return }

        let style = properties.style ?? .none
        guard style != .none, style != .hidden else { return }

        let baseFontSize = context.configuration.defaultFontSize
        let currentSize = context.pdf.style.fontSize

        guard let width = properties.width.flatMap({
            pdfBorderWidth(
                from: $0,
                currentSize: currentSize,
                baseFontSize: baseFontSize
            )
        }), width != PDF.UserSpace.Size<1>(0) else { return }

        guard let cssColor = properties.color,
              let pdfColor = PDF.Color(cssColor)
        else { return }

        context.pendingSideBorderTop = .init(
            width: width,
            style: style,
            color: pdfColor
        )
    }
}

// RawProperty<BorderTop> dispatch via BorderSideProperty (see
// W3C_CSS_Backgrounds.BorderBottom+PDF.HTML.Style.Modifier.swift).
