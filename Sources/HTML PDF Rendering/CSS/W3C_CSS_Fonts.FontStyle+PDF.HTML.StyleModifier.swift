// FontStyle+PDF.HTML.StyleModifier.swift
// CSS font-style property to PDF context translation

import PDF_Rendering
import W3C_CSS_Fonts

extension FontStyle: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .italic, .oblique, .obliqueAngle:
            context.font = context.font.italic
        case .normal:
            // Normal style - no change needed (italic is additive)
            break
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
