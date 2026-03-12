// Width+PDF.HTML.StyleModifier.swift
// CSS width property to PDF context translation

import PDF_Rendering
import PDF_Standard
public import W3C_CSS_BoxModel
import W3C_CSS_Values

extension W3C_CSS_BoxModel.Width: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(let lp):
            let currentSize = context.style.fontSize ?? configuration.defaultFontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.explicitWidth = size.width
        case .auto:
            // Auto width computed during layout
            context.explicitWidth = nil
        case .maxContent, .minContent, .fitContent, .fitContentLength, .stretch:
            // Intrinsic sizing keywords - layout engine handles these
            context.explicitWidth = nil
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
