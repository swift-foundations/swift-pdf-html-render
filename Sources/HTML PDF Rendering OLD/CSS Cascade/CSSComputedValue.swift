// CSSComputedValue.swift

import W3C_CSS_Values
import PDF_Rendering

/// Utilities for computing absolute values from relative CSS values.
///
/// CSS properties can have relative values (em, %, etc.) that need to be
/// resolved to absolute values (points) based on context.
///
/// Example:
/// ```swift
/// // Resolve 1.5em relative to 12pt parent font
/// let size = CSSComputedValue.resolveLength(
///     .em(1.5),
///     relativeTo: 12.0
/// )  // 18.0 points
/// ```
public enum CSSComputedValue {
    /// Default font size in points (browser default 16px → 12pt)
    public static let defaultFontSize: Double = 12.0

    /// Default line height multiplier
    public static let defaultLineHeight: Double = 1.2

    /// Root font size in points (for rem units)
    public static let rootFontSize: Double = 12.0

    // MARK: - Length Resolution

    /// Resolve a CSS Length to absolute points
    ///
    /// - Parameters:
    ///   - length: The CSS length value
    ///   - relativeTo: Base value for relative units (em)
    /// - Returns: The length in points
    public static func resolveLength(_ length: W3C_CSS_Values.Length, relativeTo base: Double = defaultFontSize) -> Double {
        PDF.Points(length, relativeTo: base).value
    }

    /// Resolve a CSS LengthPercentage to absolute points
    ///
    /// - Parameters:
    ///   - value: The CSS length or percentage value
    ///   - relativeTo: Base value for em units
    ///   - percentageBase: Base value for percentage calculations (e.g., container width)
    /// - Returns: The length in points
    public static func resolveLengthPercentage(
        _ value: W3C_CSS_Values.LengthPercentage,
        relativeTo base: Double,
        percentageBase: Double? = nil
    ) -> Double {
        switch value {
        case .length(let length):
            return resolveLength(length, relativeTo: base)
        case .percentage(let pct):
            let pctBase = percentageBase ?? base
            return pctBase * pct.value / 100.0
        case .calc:
            // calc() expressions would require a full parser
            return 0
        }
    }

    // MARK: - Color

    /// Resolve a CSS color to PDF.Color
    ///
    /// - Parameter cssColor: The CSS color value
    /// - Returns: PDF color
    public static func resolveColor(_ cssColor: W3C_CSS_Values.Color) -> PDF.Color {
        PDF.Color(cssColor)
    }

    // MARK: - Edge Insets (Margin/Padding)

    /// Resolve CSS edge values to PDF.EdgeInsets
    ///
    /// - Parameters:
    ///   - top: Top value
    ///   - right: Right value
    ///   - bottom: Bottom value
    ///   - left: Left value
    ///   - relativeTo: Base value for em units
    ///   - percentageBase: Base value for percentage calculations
    /// - Returns: Edge insets in points
    public static func resolveEdgeInsets(
        top: W3C_CSS_Values.LengthPercentage?,
        right: W3C_CSS_Values.LengthPercentage?,
        bottom: W3C_CSS_Values.LengthPercentage?,
        left: W3C_CSS_Values.LengthPercentage?,
        relativeTo base: Double,
        percentageBase: Double? = nil
    ) -> PDF.EdgeInsets {
        PDF.EdgeInsets(
            top: top.map { resolveLengthPercentage($0, relativeTo: base, percentageBase: percentageBase) } ?? 0,
            left: left.map { resolveLengthPercentage($0, relativeTo: base, percentageBase: percentageBase) } ?? 0,
            bottom: bottom.map { resolveLengthPercentage($0, relativeTo: base, percentageBase: percentageBase) } ?? 0,
            right: right.map { resolveLengthPercentage($0, relativeTo: base, percentageBase: percentageBase) } ?? 0
        )
    }

    // MARK: - Opacity

    /// Clamp opacity value to valid range
    ///
    /// - Parameter value: Raw opacity value
    /// - Returns: Opacity clamped to 0.0...1.0
    public static func resolveOpacity(_ value: Double) -> Double {
        max(0.0, min(1.0, value))
    }

    // MARK: - Font Size Keywords

    /// Resolve absolute font size keyword to points
    ///
    /// - Parameter keyword: Font size keyword (xx-small, x-small, small, medium, large, x-large, xx-large)
    /// - Returns: Font size in points, or nil if not a valid keyword
    public static func absoluteFontSize(for keyword: String) -> Double? {
        switch keyword.lowercased() {
        case "xx-small": return 7.5
        case "x-small": return 9.0
        case "small": return 10.5
        case "medium": return 12.0
        case "large": return 13.5
        case "x-large": return 18.0
        case "xx-large": return 24.0
        case "xxx-large": return 32.0
        default: return nil
        }
    }

    /// Resolve relative font size keyword to points
    ///
    /// - Parameters:
    ///   - keyword: Font size keyword (smaller, larger)
    ///   - parentFontSize: Parent element's font size
    /// - Returns: Font size in points, or nil if not a valid keyword
    public static func relativeFontSize(for keyword: String, parentFontSize: Double) -> Double? {
        switch keyword.lowercased() {
        case "smaller": return parentFontSize * 0.833
        case "larger": return parentFontSize * 1.2
        default: return nil
        }
    }

    // MARK: - Line Height

    /// Resolve line height value
    ///
    /// - Parameters:
    ///   - value: Line height as string (number, length, or "normal")
    ///   - fontSize: Current element's font size
    /// - Returns: Line height in points
    public static func resolveLineHeight(_ value: String, fontSize: Double) -> Double {
        let v = value.lowercased().trimmingCharacters(in: .whitespaces)

        if v == "normal" {
            return fontSize * defaultLineHeight
        }

        // Try as unitless number (multiplier)
        if let multiplier = Double(v) {
            return fontSize * multiplier
        }

        // Try parsing as length
        if let points = HTML.ElementMapping.parseFontSize(v) {
            return points
        }

        // Fallback
        return fontSize * defaultLineHeight
    }
}
