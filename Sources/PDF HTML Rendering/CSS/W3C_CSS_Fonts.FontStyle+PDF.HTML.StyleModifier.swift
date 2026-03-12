// FontStyle+PDF.HTML.StyleModifier.swift
// CSS font-style property to PDF context translation

import PDF_Rendering
public import W3C_CSS_Fonts

extension W3C_CSS_Fonts.FontStyle: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .italic, .oblique, .obliqueAngle:
            context.style.font = context.style.font.italic
        case .normal:
            // Normal style - no change needed (italic is additive)
            break
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
