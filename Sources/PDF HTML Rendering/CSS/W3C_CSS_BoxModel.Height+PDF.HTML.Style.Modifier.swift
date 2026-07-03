// W3C_CSS_BoxModel.Height+PDF.HTML.Style.Modifier.swift
// CSS height property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.Height: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(let lp):
            let currentSize = context.style.fontSize ?? configuration.defaultFontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.constraint.height = size.height

        case .auto:
            // Auto height computed during layout
            context.constraint.height = nil

        case .maxContent, .minContent, .fitContent, .fitContentLength, .stretch:
            // Intrinsic sizing keywords - layout engine handles these
            context.constraint.height = nil

        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
