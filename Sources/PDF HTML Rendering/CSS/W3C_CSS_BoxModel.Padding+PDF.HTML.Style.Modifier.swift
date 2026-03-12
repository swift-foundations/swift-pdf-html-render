// W3C_CSS_BoxModel.Padding+PDF.HTML.Style.Modifier.swift
// CSS padding property to PDF context translation

import PDF_Rendering
import PDF_Standard
public import W3C_CSS_BoxModel
import W3C_CSS_Values

extension W3C_CSS_BoxModel.Padding: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        let currentSize = context.style.fontSize ?? configuration.defaultFontSize

        switch self {
        case .all(let lp):
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.paddingTop = size.height
            context.paddingRight = size.width
            context.paddingBottom = size.height
            context.paddingLeft = size.width

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
            context.paddingTop = vSize.height
            context.paddingRight = hSize.width
            context.paddingBottom = vSize.height
            context.paddingLeft = hSize.width

        case .topHorizontalBottom(let top, let horizontal, let bottom):
            let topSize = PDF.UserSpace.Size<1>(
                top,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            let hSize = PDF.UserSpace.Size<1>(
                horizontal,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            let bottomSize = PDF.UserSpace.Size<1>(
                bottom,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.paddingTop = topSize.height
            context.paddingRight = hSize.width
            context.paddingBottom = bottomSize.height
            context.paddingLeft = hSize.width

        case .sides(let top, let right, let bottom, let left):
            let topSize = PDF.UserSpace.Size<1>(
                top,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            let rightSize = PDF.UserSpace.Size<1>(
                right,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            let bottomSize = PDF.UserSpace.Size<1>(
                bottom,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            let leftSize = PDF.UserSpace.Size<1>(
                left,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.paddingTop = topSize.height
            context.paddingRight = rightSize.width
            context.paddingBottom = bottomSize.height
            context.paddingLeft = leftSize.width

        case .named(let namedSides):
            if let top = namedSides.top {
                let size = PDF.UserSpace.Size<1>(
                    top,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.paddingTop = size.height
            }
            if let right = namedSides.right {
                let size = PDF.UserSpace.Size<1>(
                    right,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.paddingRight = size.width
            }
            if let bottom = namedSides.bottom {
                let size = PDF.UserSpace.Size<1>(
                    bottom,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.paddingBottom = size.height
            }
            if let left = namedSides.left {
                let size = PDF.UserSpace.Size<1>(
                    left,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.paddingLeft = size.width
            }

        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
