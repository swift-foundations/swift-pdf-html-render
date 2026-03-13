// W3C_CSS_Color.Color+PDF.HTML.Style.Modifier.swift
// CSS color property to PDF context translation
//
// Uses CSS Standard's IEC 61966-2-1 sRGB conversions.

import PDF_Rendering

extension W3C_CSS_Color.Color: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .color(let color):
            context.style.color = PDF.Color(color) ?? context.style.color
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
