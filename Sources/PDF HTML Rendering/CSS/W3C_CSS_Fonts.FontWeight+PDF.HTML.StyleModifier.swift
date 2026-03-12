// FontWeight+PDF.HTML.StyleModifier.swift
// CSS font-weight property to PDF context translation

import PDF_Rendering
public import W3C_CSS_Fonts

extension W3C_CSS_Fonts.FontWeight: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .bold, .bolder:
            context.style.font = context.style.font.bold
        case .number(let weight) where weight >= 600:
            context.style.font = context.style.font.bold
        case .normal, .lighter:
            // For lighter/normal, we'd need to reset weight but keep style
            // The .regular property resets both, so this isn't perfect
            // but PDF fonts have limited weight support anyway
            break
        case .number:
            // Weight < 600, standard weight (no change needed)
            break
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
