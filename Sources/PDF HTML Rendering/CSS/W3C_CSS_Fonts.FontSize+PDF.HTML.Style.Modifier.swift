// W3C_CSS_Fonts.FontSize+PDF.HTML.Style.Modifier.swift
// CSS font-size property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Fonts.FontSize: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        let currentSize = context.style.fontSize
        switch self {
        case .absoluteSize(let size):
            context.style.fontSize = PDF.UserSpace.Size<1>(
                size,
                baseFontSize: configuration.defaultFontSize
            )

        case .relativeSize(let size):
            context.style.fontSize = PDF.UserSpace.Size<1>(size, currentSize: currentSize)

        case .lengthPercentage(let lp):
            context.style.fontSize = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
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
