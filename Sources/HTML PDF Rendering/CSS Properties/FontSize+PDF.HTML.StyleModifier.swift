// FontSize+PDF.HTML.StyleModifier.swift
// CSS font-size property to PDF context translation

import PDF_Rendering
import PDF_Standard
import W3C_CSS_Fonts
import W3C_CSS_Values

extension W3C_CSS_Fonts.FontSize: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .absoluteSize(let size):
            context.fontSize = size.toPoints(baseFontSize: configuration.defaultFontSize)
        case .relativeSize(let size):
            context.fontSize = size.toPoints(currentSize: context.fontSize)
        case .lengthPercentage(let lp):
            context.fontSize = lp.toPoints(
                currentSize: context.fontSize,
                baseFontSize: configuration.defaultFontSize
            )
        case .math:
            // Math font size - use default
            break
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}

// MARK: - AbsoluteSize to Points

extension W3C_CSS_Fonts.AbsoluteSize {
    /// Convert absolute size keywords to points
    ///
    /// Based on CSS spec comments in AbsoluteSize.swift:
    /// - medium is the base (user's preferred font size)
    /// - xx-small: 60% of medium
    /// - x-small: 75% of medium
    /// - small: 89% of medium
    /// - large: 120% of medium
    /// - x-large: 150% of medium
    /// - xx-large: 200% of medium
    /// - xxx-large: 300% of medium
    func toPoints(baseFontSize: PDF.UserSpace.Unit) -> PDF.UserSpace.Unit {
        switch self {
        case .xxSmall:
            return baseFontSize * 0.6
        case .xSmall:
            return baseFontSize * 0.75
        case .small:
            return baseFontSize * 0.89
        case .medium:
            return baseFontSize
        case .large:
            return baseFontSize * 1.2
        case .xLarge:
            return baseFontSize * 1.5
        case .xxLarge:
            return baseFontSize * 2.0
        case .xxxLarge:
            return baseFontSize * 3.0
        }
    }
}

// MARK: - RelativeSize to Points

extension W3C_CSS_Fonts.RelativeSize {
    /// Convert relative size keywords to points
    func toPoints(currentSize: PDF.UserSpace.Unit) -> PDF.UserSpace.Unit {
        let ratio = 1.2
        switch self {
        case .smaller:
            return currentSize / ratio
        case .larger:
            return currentSize * ratio
        }
    }
}

// MARK: - LengthPercentage to Points

extension LengthPercentage {
    /// Convert CSS length-percentage to points for PDF
    func toPoints(
        currentSize: PDF.UserSpace.Unit,
        baseFontSize: PDF.UserSpace.Unit
    ) -> PDF.UserSpace.Unit {
        switch self {
        case .length(let length):
            return length.toPoints(currentSize: currentSize, baseFontSize: baseFontSize)
        case .percentage(let percentage):
            // Percentage of current font size
            return currentSize * (percentage.value / 100.0)
        case .calc:
            // calc() expressions can't be evaluated statically
            return currentSize
        }
    }
}

// MARK: - Length to Points

extension Length {
    /// Convert CSS length to points for PDF
    ///
    /// PDF uses points (pt) as the native unit. Conversion ratios:
    /// - 1pt = 1pt
    /// - 1px ≈ 0.75pt (at 96 DPI)
    /// - 1in = 72pt
    /// - 1cm = 28.35pt
    /// - 1mm = 2.835pt
    /// - 1em = current font size
    /// - 1rem = root font size
    func toPoints(
        currentSize: PDF.UserSpace.Unit,
        baseFontSize: PDF.UserSpace.Unit
    ) -> PDF.UserSpace.Unit {
        switch self {
        case .length(let value, let unit):
            switch unit {
            case .pt:
                return PDF.UserSpace.Unit(value)
            case .px:
                // 96 DPI: 1px = 72/96 pt = 0.75pt
                return PDF.UserSpace.Unit(value * 0.75)
            case .em:
                return currentSize * value
            case .rem:
                return baseFontSize * value
            case .in:
                return PDF.UserSpace.Unit(value * 72.0)
            case .cm:
                return PDF.UserSpace.Unit(value * 28.3465)
            case .mm:
                return PDF.UserSpace.Unit(value * 2.83465)
            case .pc:
                // 1 pica = 12 points
                return PDF.UserSpace.Unit(value * 12.0)
            case .ex:
                // Approximate ex as 0.5em
                return currentSize * (value * 0.5)
            case .ch:
                // Approximate ch as 0.5em
                return currentSize * (value * 0.5)
            case .lh:
                // Line height - approximate as 1.2em
                return currentSize * (value * 1.2)
            case .vw, .vh, .vmin, .vmax:
                // Viewport units not meaningful for PDF font size
                return currentSize
            case .fr:
                // Grid units not meaningful for font size
                return currentSize
            case .q:
                // 1q = 0.25mm = 0.709pt
                return PDF.UserSpace.Unit(value * 0.70866)
            case .cap:
                // Cap height - approximate as 0.7em
                return currentSize * (value * 0.7)
            case .ic:
                // Ideographic character - approximate as 1em
                return currentSize * value
            case .rlh:
                // Root line height - approximate as 1.2 * base
                return baseFontSize * (value * 1.2)
            }
        case .keyword:
            // Keywords like auto don't apply to font-size
            return currentSize
        case .calc:
            // calc() can't be evaluated statically
            return currentSize
        case .global:
            return currentSize
        }
    }
}
