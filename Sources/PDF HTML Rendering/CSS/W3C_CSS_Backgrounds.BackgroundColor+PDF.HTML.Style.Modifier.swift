// W3C_CSS_Backgrounds.BackgroundColor+PDF.HTML.Style.Modifier.swift
// CSS background-color property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Backgrounds.BackgroundColor: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .color(let color):
            // Use highlight text markup for background colors
            // Convert CSS color to annotation color
            if let pdfColor = PDF.Color(color) {
                let annotationColor: PDF.Annotation.Color = switch pdfColor {
                case .gray(let g): .gray(g)
                case .rgb(let r, let g, let b): .rgb(red: r, green: g, blue: b)
                case .cmyk(let c, let m, let y, let k): .cmyk(cyan: c, magenta: m, yellow: y, black: k)
                }
                context.style.textMarkup = .highlight(annotationColor)
            }
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
