// W3C_CSS_Text.LineHeight+PDF.HTML.Style.Modifier.swift
// CSS line-height property to PDF context translation

import Dimension_Primitives
import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Text.LineHeight: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .normal:
            // CSS `normal` defers to the user-agent default. Per
            // `PDF.Context.Style.defaults` the configured default is 1.2;
            // pin to that value so a later modifier doesn't see an
            // inherited tighter multiplier.
            context.style.lineHeight = 1.2

        case .multiple(let value):
            // Unitless multiplier — CSS's preferred form. Maps directly
            // to `Scale<1, Double>` since the resolved `line.height` is
            // `fontSize * lineHeight` per `PDF.Context.Style.Resolved`.
            context.style.lineHeight = Dimension_Primitives.Scale(value)

        case .lengthPercentage(let lp):
            switch lp {
            case .percentage(let percentage):
                context.style.lineHeight = Dimension_Primitives.Scale(percentage.value / 100.0)
            case .length:
                // Absolute lengths (e.g., `line-height: 24pt`) require a
                // length-to-ratio conversion against the current font
                // size. The Geometry types in swift-standards don't yet
                // expose a public Size<1> → Scalar accessor; deferred
                // pending that infrastructure. Uncommon in practice —
                // CSS authors prefer unit-less multipliers and percentages.
                break
            case .calc:
                // `calc()` cannot be evaluated statically — preserve
                // current value.
                break
            }

        case .global:
            break
        }
    }
}
