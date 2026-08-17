// W3C_CSS_BoxModel.Margin+PDF.HTML.Style.Modifier.swift
// CSS margin property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.Margin: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        let currentSize = context.style.fontSize ?? configuration.defaultFontSize

        switch self {
        case .auto:
            // Auto margins handled during layout
            context.margin.top = nil
            context.margin.right = nil
            context.margin.bottom = nil
            context.margin.left = nil

        case .all(let lp):
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.margin.top = size.height
            context.margin.right = size.width
            context.margin.bottom = size.height
            context.margin.left = size.width

        case .verticalHorizontal(let vertical, let horizontal):
            let vSize = PDF.UserSpace.Size<1>(
                vertical,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            let hSize = PDF.UserSpace.Size<1>(
                horizontal,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.margin.top = vSize.height
            context.margin.right = hSize.width
            context.margin.bottom = vSize.height
            context.margin.left = hSize.width

        case .topHorizontalBottom(let top, let horizontal, let bottom):
            top.apply(to: &context, configuration: configuration)
            let hSize = PDF.UserSpace.Size<1>(
                horizontal,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.margin.right = hSize.width
            context.margin.left = hSize.width
            bottom.apply(to: &context, configuration: configuration)

        case .sides(let top, let right, let bottom, let left):
            top.apply(to: &context, configuration: configuration)
            right.apply(to: &context, configuration: configuration)
            bottom.apply(to: &context, configuration: configuration)
            left.apply(to: &context, configuration: configuration)

        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
