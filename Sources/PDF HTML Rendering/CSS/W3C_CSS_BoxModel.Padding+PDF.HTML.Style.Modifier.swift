// W3C_CSS_BoxModel.Padding+PDF.HTML.Style.Modifier.swift
// CSS padding property to PDF context translation

import PDF_Rendering
import PDF_Standard

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
            context.padding.top = size.height
            context.padding.right = size.width
            context.padding.bottom = size.height
            context.padding.left = size.width

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
            context.padding.top = vSize.height
            context.padding.right = hSize.width
            context.padding.bottom = vSize.height
            context.padding.left = hSize.width

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
            context.padding.top = topSize.height
            context.padding.right = hSize.width
            context.padding.bottom = bottomSize.height
            context.padding.left = hSize.width

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
            context.padding.top = topSize.height
            context.padding.right = rightSize.width
            context.padding.bottom = bottomSize.height
            context.padding.left = leftSize.width

        case .named(let namedSides):
            if let top = namedSides.top {
                let size = PDF.UserSpace.Size<1>(
                    top,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.padding.top = size.height
            }
            if let right = namedSides.right {
                let size = PDF.UserSpace.Size<1>(
                    right,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.padding.right = size.width
            }
            if let bottom = namedSides.bottom {
                let size = PDF.UserSpace.Size<1>(
                    bottom,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.padding.bottom = size.height
            }
            if let left = namedSides.left {
                let size = PDF.UserSpace.Size<1>(
                    left,
                    currentSize: currentSize,
                    baseFontSize: configuration.defaultFontSize
                )
                context.padding.left = size.width
            }

        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
