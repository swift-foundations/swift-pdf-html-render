//
//  File.swift
//  swift-pdf-html-rendering
//
//  Created by Coen ten Thije Boonkkamp on 04/12/2025.
//

import CSS_Standard
import PDF_Rendering
import PDF_Standard

extension PDF.UserSpace.Unit {
    public init(
        _ absoluteSize: W3C_CSS_Fonts.AbsoluteSize,
        baseFontSize: PDF.UserSpace.Unit
    ) {
        switch absoluteSize {
        case .xxSmall:
            self = baseFontSize * 0.6
        case .xSmall:
            self = baseFontSize * 0.75
        case .small:
            self = baseFontSize * 0.89
        case .medium:
            self = baseFontSize
        case .large:
            self = baseFontSize * 1.2
        case .xLarge:
            self = baseFontSize * 1.5
        case .xxLarge:
            self = baseFontSize * 2.0
        case .xxxLarge:
            self = baseFontSize * 3.0
        }
    }
}

extension PDF.UserSpace.Unit {
    public init(
        _ relativeSize: W3C_CSS_Fonts.RelativeSize,
        currentSize: PDF.UserSpace.Unit
    ) {
        let ratio = 1.2
        switch relativeSize {
        case .smaller:
            self = currentSize / ratio
        case .larger:
            self = currentSize * ratio
        }
    }
}

extension PDF.UserSpace.Unit {
    public init(
        _ lengthPercentage: LengthPercentage,
        currentSize: PDF.UserSpace.Unit,
        baseFontSize: PDF.UserSpace.Unit
    ) {
        switch lengthPercentage {
        case .length(let length):
            self = PDF.UserSpace.Unit(length, currentSize: currentSize, baseFontSize: baseFontSize)
        case .percentage(let percentage):
            // Percentage of current font size
            self = currentSize * (percentage.value / 100.0)
        case .calc:
            // calc() expressions can't be evaluated statically
            self = currentSize
        }
    }
}

extension PDF.UserSpace.Unit {
    public init(
        _ length: Length,
        currentSize: PDF.UserSpace.Unit,
        baseFontSize: PDF.UserSpace.Unit
    ) {
        switch length {
        case .length(let value, let unit):
            switch unit {
            case .pt:
                self = PDF.UserSpace.Unit(value)
            case .px:
                // 96 DPI: 1px = 72/96 pt = 0.75pt
                self = PDF.UserSpace.Unit(value * 0.75)
            case .em:
                self = currentSize * value
            case .rem:
                self = baseFontSize * value
            case .in:
                self = PDF.UserSpace.Unit(value * 72.0)
            case .cm:
                self = PDF.UserSpace.Unit(value * 28.3465)
            case .mm:
                self = PDF.UserSpace.Unit(value * 2.83465)
            case .pc:
                // 1 pica = 12 points
                self = PDF.UserSpace.Unit(value * 12.0)
            case .ex:
                // Approximate ex as 0.5em
                self = currentSize * (value * 0.5)
            case .ch:
                // Approximate ch as 0.5em
                self = currentSize * (value * 0.5)
            case .lh:
                // Line height - approximate as 1.2em
                self = currentSize * (value * 1.2)
            case .vw, .vh, .vmin, .vmax:
                // Viewport units not meaningful for PDF font size
                self = currentSize
            case .fr:
                // Grid units not meaningful for font size
                self = currentSize
            case .q:
                // 1q = 0.25mm = 0.709pt
                self = PDF.UserSpace.Unit(value * 0.70866)
            case .cap:
                // Cap height - approximate as 0.7em
                self = currentSize * (value * 0.7)
            case .ic:
                // Ideographic character - approximate as 1em
                self = currentSize * value
            case .rlh:
                // Root line height - approximate as 1.2 * base
                self = baseFontSize * (value * 1.2)
            }
        case .keyword:
            // Keywords like auto don't apply to font-size
            self = currentSize
        case .calc:
            // calc() can't be evaluated statically
            self = currentSize
        case .global:
            self = currentSize
        }
    }
}
