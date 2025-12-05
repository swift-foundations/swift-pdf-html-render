// BackgroundColor+PDF.HTML.StyleModifier.swift
// CSS background-color property to PDF context translation

import PDF_Rendering
import PDF_Standard
import W3C_CSS_Backgrounds

extension W3C_CSS_Backgrounds.BackgroundColor: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .color(let color):
            context.textBackgroundColor = PDF.Color(color)
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
