// W3C_CSS_Backgrounds.BorderLeft+PDF.HTML.Style.Modifier.swift
// CSS border-left property to PDF context translation.
// Note: BorderLeft's `case properties` carries 3 separate associated
// values (width keyword, style, color) — asymmetric vs BorderTop/Right/
// Bottom which carry a single `Properties` struct.

public import PDF_Rendering
import PDF_Standard
import W3C_CSS_Values

extension W3C_CSS_Backgrounds.BorderLeft: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        guard case .properties(let widthKeyword, let cssStyle, let cssColor) = self else {
            return
        }

        let style = cssStyle ?? .none
        guard style != .none, style != .hidden else { return }

        let baseFontSize = context.configuration.defaultFontSize
        let currentSize = context.pdf.style.fontSize

        guard let width = widthKeyword.flatMap({
            pdfBorderWidth(
                fromKeyword: $0,
                currentSize: currentSize,
                baseFontSize: baseFontSize
            )
        }), width != PDF.UserSpace.Size<1>(0) else { return }

        guard let cssColor, let pdfColor = PDF.Color(cssColor) else { return }

        context.pendingSideBorderLeft = .init(
            width: width,
            style: style,
            color: pdfColor
        )
    }
}

// RawProperty<BorderLeft> dispatch via BorderSideProperty (see
// W3C_CSS_Backgrounds.BorderBottom+PDF.HTML.Style.Modifier.swift).
// BorderLeft's asymmetric case shape (BorderWidth.Width keyword vs full
// BorderWidth) is handled in the BorderSideProperty conformance.
