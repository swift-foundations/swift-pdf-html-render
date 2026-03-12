// W3C_CSS_BoxModel.Margin+PDF.HTML.Style.Modifier.swift
// CSS margin property to PDF context translation

import PDF_Rendering
import PDF_Standard
public import W3C_CSS_BoxModel
import W3C_CSS_Values

extension W3C_CSS_BoxModel.Margin: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        let currentSize = context.style.fontSize ?? configuration.defaultFontSize

        switch self {
        case .auto:
            // Auto margins handled during layout
            context.marginTop = nil
            context.marginRight = nil
            context.marginBottom = nil
            context.marginLeft = nil

        case .all(let lp):
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.marginTop = size.height
            context.marginRight = size.width
            context.marginBottom = size.height
            context.marginLeft = size.width

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
            context.marginTop = vSize.height
            context.marginRight = hSize.width
            context.marginBottom = vSize.height
            context.marginLeft = hSize.width

        case .topHorizontalBottom(let top, let horizontal, let bottom):
            top.apply(to: &context, configuration: configuration)
            let hSize = PDF.UserSpace.Size<1>(
                horizontal,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.marginRight = hSize.width
            context.marginLeft = hSize.width
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
