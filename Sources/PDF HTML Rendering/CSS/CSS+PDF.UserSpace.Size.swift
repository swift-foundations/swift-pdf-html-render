//
//  CSS+PDF.UserSpace.Size.swift
//  swift-pdf-html-rendering
//
//  Created by Coen ten Thije Boonkkamp on 12/12/2025.
//

import CSS_Standard
import Dimension_Primitives
import PDF_Rendering
import PDF_Standard
public import W3C_CSS_Fonts
public import W3C_CSS_Values

extension PDF.UserSpace.Size where N == 1 {
    /// Create a 1D size from a CSS absolute font size.
    ///
    /// - Parameters:
    ///   - absoluteSize: The CSS absolute size keyword
    ///   - baseFontSize: The base font size (typically from configuration)
    public init(
        _ absoluteSize: W3C_CSS_Fonts.AbsoluteSize,
        baseFontSize: Self
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

extension PDF.UserSpace.Size where N == 1 {
    /// Create a 1D size from a CSS relative font size.
    ///
    /// - Parameters:
    ///   - relativeSize: The CSS relative size keyword (smaller/larger)
    ///   - currentSize: The current font size
    public init(
        _ relativeSize: W3C_CSS_Fonts.RelativeSize,
        currentSize: Self
    ) {
        switch relativeSize {
        case .smaller:
            self = currentSize / 1.2
        case .larger:
            self = currentSize * 1.2
        }
    }
}

extension PDF.UserSpace.Size where N == 1 {
    /// Create a 1D size from a CSS length-percentage.
    ///
    /// - Parameters:
    ///   - lengthPercentage: The CSS length-percentage value
    ///   - currentSize: The current font size (for em, ex, etc.)
    ///   - baseFontSize: The base font size (for rem)
    public init(
        _ lengthPercentage: LengthPercentage,
        currentSize: Self,
        baseFontSize: Self
    ) {
        switch lengthPercentage {
        case .length(let length):
            self = Self(length, currentSize: currentSize, baseFontSize: baseFontSize)
        case .percentage(let percentage):
            // Percentage of current font size
            self = currentSize * Scale(percentage.value / 100.0)
        case .calc(_):
            // calc() expressions can't be evaluated statically
            self = currentSize
        }
    }
}

extension PDF.UserSpace.Size where N == 1 {
    /// Create a 1D size from a CSS length.
    ///
    /// - Parameters:
    ///   - length: The CSS length value
    ///   - currentSize: The current font size (for em, ex, etc.)
    ///   - baseFontSize: The base font size (for rem)
    public init(
        _ length: W3C_CSS_Values.Length,
        currentSize: Self,
        baseFontSize: Self
    ) {
        switch length {
        case .length(let value, let unit):
            switch unit {
            case .pt:
                self = Self(value)
            case .px:
                // 96 DPI: 1px = 72/96 pt = 0.75pt
                self = Self(value * 0.75)
            case .em:
                self = currentSize * Scale(value)
            case .rem:
                self = baseFontSize * Scale(value)
            case .in:
                self = Self(value * 72.0)
            case .cm:
                self = Self(value * 28.3465)
            case .mm:
                self = Self(value * 2.83465)
            case .pc:
                // 1 pica = 12 points
                self = Self(value * 12.0)
            case .ex:
                // Approximate ex as 0.5em
                self = currentSize * Scale(value * 0.5)
            case .ch:
                // Approximate ch as 0.5em
                self = currentSize * Scale(value * 0.5)
            case .lh:
                // Line height - approximate as 1.2em
                self = currentSize * Scale(value * 1.2)
            case .vw, .vh, .vmin, .vmax:
                // Viewport units not meaningful for PDF font size
                self = currentSize
            case .fr:
                // Grid units not meaningful for font size
                self = currentSize
            case .q:
                // 1q = 0.25mm = 0.709pt
                self = Self(value * 0.70866)
            case .cap:
                // Cap height - approximate as 0.7em
                self = currentSize * Scale(value * 0.7)
            case .ic:
                // Ideographic character - approximate as 1em
                self = currentSize * Scale(value)
            case .rlh:
                // Root line height - approximate as 1.2 * base
                self = baseFontSize * Scale(value * 1.2)
            }
        case .keyword:
            // Keywords like auto don't apply to font-size
            self = currentSize
        case .calc(_):
            // calc() can't be evaluated statically
            self = currentSize
        case .global:
            self = currentSize
        }
    }
}
