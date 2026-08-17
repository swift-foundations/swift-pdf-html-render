// W3C_CSS_BoxModel.MarginBottom+PDF.HTML.Style.Modifier.swift
// CSS margin-bottom property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.MarginBottom: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(let lp):
            let currentSize = context.style.fontSize ?? configuration.defaultFontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.margin.bottom = size.height

        case .auto:
            // Auto margins handled during layout
            context.margin.bottom = nil

        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
