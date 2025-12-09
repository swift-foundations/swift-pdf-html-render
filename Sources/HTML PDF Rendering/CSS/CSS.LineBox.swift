// CSS.LineBox.swift
//
// Line box geometry for text layout following CSS inline formatting model.
// This implements the "half-leading" model where extra line height is
// distributed symmetrically above and below the text content.
//
// This is a CSS concept (CSS 2.1 Section 10.8), not a PDF concept,
// so it belongs in the HTML-to-PDF rendering layer.

import PDF_Rendering

extension PDF.HTML {
    /// Line box geometry following CSS inline formatting model.
    ///
    /// Per CSS 2.1 Section 10.8, the height of a line box is determined by:
    /// 1. Computing the line-height for each inline element
    /// 2. Distributing "leading" symmetrically above and below the text
    ///
    /// The half-leading model ensures text is vertically centered within its line box,
    /// providing symmetric spacing above and below glyphs.
    ///
    /// ## Geometric Relationships
    ///
    /// ```
    /// ┌─────────────────────────────────────────┐ ← Line box top
    /// │           half-leading                   │
    /// ├─────────────────────────────────────────┤ ← Ascender line
    /// │           ascender height                │
    /// │   ████  ██  █████                       │ ← Glyphs
    /// ├─────────────────────────────────────────┤ ← BASELINE
    /// │           |descender|                    │
    /// ├─────────────────────────────────────────┤ ← Descender line
    /// │           half-leading                   │
    /// └─────────────────────────────────────────┘ ← Line box bottom
    /// ```
    ///
    /// ## Formulas
    ///
    /// - `contentHeight = ascender - descender` (descender is negative)
    /// - `halfLeading = max(0, (lineHeight - contentHeight) / 2)`
    /// - `baselineOffset = halfLeading + ascender`
    /// - `belowBaseline = halfLeading + |descender|`
    ///
    /// ## Reference
    ///
    /// - CSS 2.1 Section 10.8 — Line height calculations
    /// - ISO 32000-2:2020 Section 9.8 — Font metrics
    public struct LineBox: Sendable, Equatable {
        /// Total height of the line box in user space units
        public let height: PDF.UserSpace.Height

        /// Distance from the top of the line box to the baseline
        ///
        /// This equals: `halfLeading + ascender`
        public let baselineOffset: PDF.UserSpace.Unit

        /// Distance from the baseline to the bottom of the line box
        ///
        /// This equals: `halfLeading + |descender|`
        public let belowBaseline: PDF.UserSpace.Unit

        /// Half-leading value (leading distributed symmetrically)
        ///
        /// `halfLeading = max(0, (lineHeight - contentHeight) / 2)`
        /// where `contentHeight = ascender - descender`
        public let halfLeading: PDF.UserSpace.Unit

        /// Create a line box from font metrics and line-height multiplier
        ///
        /// - Parameters:
        ///   - metrics: Font metrics from the font descriptor (Section 9.8)
        ///   - fontSize: Font size in user space units
        ///   - lineHeightMultiplier: CSS line-height multiplier (e.g., 1.2, 1.5)
        public init(
            metrics: PDF.Font.Metrics,
            fontSize: PDF.UserSpace.Unit,
            lineHeightMultiplier: Double
        ) {
            let ascender = metrics.ascender(atSize: fontSize)
            let descender = metrics.descender(atSize: fontSize)  // negative value
            let contentHeight = ascender - descender  // ascender - (negative) = ascender + |descender|
            let lineHeight = fontSize * lineHeightMultiplier
            let halfLeading = Swift.max(PDF.UserSpace.Unit(0), (lineHeight - contentHeight) / PDF.UserSpace.Unit(2))

            self.height = PDF.UserSpace.Height(lineHeight)
            self.halfLeading = halfLeading
            self.baselineOffset = halfLeading + ascender
            self.belowBaseline = halfLeading + (-descender)  // convert negative descender to positive
        }

        /// Create a line box from font metrics and explicit line height
        ///
        /// - Parameters:
        ///   - metrics: Font metrics from the font descriptor (Section 9.8)
        ///   - fontSize: Font size in user space units
        ///   - lineHeight: Explicit line height in user space units
        public init(
            metrics: PDF.Font.Metrics,
            fontSize: PDF.UserSpace.Unit,
            lineHeight: PDF.UserSpace.Unit
        ) {
            let ascender = metrics.ascender(atSize: fontSize)
            let descender = metrics.descender(atSize: fontSize)
            let contentHeight = ascender - descender
            let halfLeading = Swift.max(PDF.UserSpace.Unit(0), (lineHeight - contentHeight) / PDF.UserSpace.Unit(2))

            self.height = PDF.UserSpace.Height(lineHeight)
            self.halfLeading = halfLeading
            self.baselineOffset = halfLeading + ascender
            self.belowBaseline = halfLeading + (-descender)
        }
    }
}
