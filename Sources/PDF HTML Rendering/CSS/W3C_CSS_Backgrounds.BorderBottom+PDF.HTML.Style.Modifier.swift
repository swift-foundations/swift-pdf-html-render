// W3C_CSS_Backgrounds.BorderBottom+PDF.HTML.Style.Modifier.swift
// CSS border-bottom property to PDF context translation.
// Per CSS Backgrounds 3 §3, border-bottom is a longhand sibling of the
// border shorthand and applies only to the element's bottom edge.

public import PDF_Rendering
public import CSS_HTML_Rendering
import PDF_Standard
import W3C_CSS_Values

extension W3C_CSS_Backgrounds.BorderBottom: PDF.HTML.Style.Context.Modifier {
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

        context.pendingSideBorderBottom = .init(
            width: width,
            style: style,
            color: pdfColor
        )
    }
}

/// swift-css emits `.css.border(.bottom, ...)` (and per-side siblings) as
/// `inlineStyle(RawProperty<BorderBottom>("1px solid #000"))` — string-
/// based. The conditional conformance below covers ALL per-side longhand
/// types via the shared `BorderSideProperty` protocol so a single
/// conformance on the generic `RawProperty<P>` doesn't violate Swift's
/// "no more than one conditional conformance" rule.
extension RawProperty: PDF.HTML.Style.Context.Modifier
    where PropertyType: BorderSideProperty
{
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
