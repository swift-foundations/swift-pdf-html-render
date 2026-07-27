// W3C_CSS_BoxModel.Width+PDF.HTML.Style.Modifier.swift
// CSS width property to PDF context translation

import Dimension_Primitives
import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.Width: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(.percentage(let percentage)):
            // Per CSS 2.1 §10.3.4 / CSS Box Sizing 3 §6.3: width N% is
            // percentage of the containing block's WIDTH, not of font size.
            // The shared `PDF.UserSpace.Size(lp, currentSize:, baseFontSize:)`
            // init resolves percentages against the font size, which is the
            // correct reference for font-size and line-height but the wrong
            // one for layout-related properties. Handle %-form explicitly.
            context.constraint.width =
                context.layout.box.width
                * Dimension_Primitives.Scale(percentage.value / 100.0)

        case .lengthPercentage(let lp):
            // Length form (px, em, pt, etc.) — relative to current/base font
            // size, which is the correct reference for absolute length units.
            let currentSize = context.style.fontSize ?? configuration.defaultFontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.constraint.width = size.width

        case .auto:
            // Auto width computed during layout
            context.constraint.width = nil

        case .maxContent, .minContent, .fitContent, .fitContentLength, .stretch:
            // Intrinsic sizing keywords - layout engine handles these
            context.constraint.width = nil

        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}
