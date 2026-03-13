// W3C_CSS_BoxModel.MarginLeft+PDF.HTML.Style.Modifier.swift
// CSS margin-left property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.MarginLeft: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(let lp):
            let currentSize = context.style.fontSize ?? configuration.defaultFontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.margin.left = size.width
        case .auto:
            // Auto margins handled during layout
            context.margin.left = nil
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
