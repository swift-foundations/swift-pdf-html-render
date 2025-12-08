// FontSize+PDF.HTML.StyleModifier.swift
// CSS font-size property to PDF context translation

import PDF_Rendering
import PDF_Standard
import W3C_CSS_Fonts
import W3C_CSS_Values

extension W3C_CSS_Fonts.FontSize: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .absoluteSize(let size):
            context.style.fontSize = PDF.UserSpace.Unit(size, baseFontSize: configuration.defaultFontSize)
        case .relativeSize(let size):
            context.style.fontSize = PDF.UserSpace.Unit(size, currentSize: context.style.fontSize)
        case .lengthPercentage(let lp):
            context.style.fontSize = PDF.UserSpace.Unit(
                lp,
                currentSize: context.style.fontSize,
                baseFontSize: configuration.defaultFontSize
            )
        case .math:
            // Math font size - use default
            break
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
