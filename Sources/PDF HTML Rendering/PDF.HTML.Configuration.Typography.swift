// PDF.HTML.Configuration.Typography.swift
// Typography scale settings for subscript, superscript, and small text

import Dimension_Primitives

extension PDF.HTML.Configuration {
    /// Typography scale settings for subscript, superscript, and small text.
    public struct Typography: Sendable, Equatable {
        /// Scale factor for subscript text (default: 0.83, i.e., 83% of base size)
        public var subscriptScale: Dimension_Primitives.Scale<1, Double>

        /// Scale factor for superscript text (default: 0.83)
        public var superscriptScale: Dimension_Primitives.Scale<1, Double>

        /// Scale factor for <small> tag text (default: 0.83)
        public var smallScale: Dimension_Primitives.Scale<1, Double>

        /// Vertical offset for subscript as em fraction (default: 0.2, negative direction)
        public var subscriptOffset: Dimension_Primitives.Scale<1, Double>

        /// Vertical offset for superscript as em fraction (default: 0.4, positive direction)
        public var superscriptOffset: Dimension_Primitives.Scale<1, Double>

        public init(
            subscriptScale: Dimension_Primitives.Scale<1, Double> = 0.83,
            superscriptScale: Dimension_Primitives.Scale<1, Double> = 0.83,
            smallScale: Dimension_Primitives.Scale<1, Double> = 0.83,
            subscriptOffset: Dimension_Primitives.Scale<1, Double> = 0.2,
            superscriptOffset: Dimension_Primitives.Scale<1, Double> = 0.4
        ) {
            self.subscriptScale = subscriptScale
            self.superscriptScale = superscriptScale
            self.smallScale = smallScale
            self.subscriptOffset = subscriptOffset
            self.superscriptOffset = superscriptOffset
        }
    }
}
