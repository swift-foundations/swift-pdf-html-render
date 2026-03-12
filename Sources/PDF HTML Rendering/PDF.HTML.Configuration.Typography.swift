// PDF.HTML.Configuration.Typography.swift
// Typography scale settings for subscript, superscript, and small text

import Dimension_Primitives

extension PDF.HTML.Configuration {
    /// Typography scale settings for subscript, superscript, and small text.
    public struct Typography: Sendable, Equatable {
        /// Scale factor for subscript text (default: 0.83, i.e., 83% of base size)
        public var subscriptScale: Scale<1, Double>

        /// Scale factor for superscript text (default: 0.83)
        public var superscriptScale: Scale<1, Double>

        /// Scale factor for <small> tag text (default: 0.83)
        public var smallScale: Scale<1, Double>

        /// Vertical offset for subscript as em fraction (default: 0.2, negative direction)
        public var subscriptOffset: Scale<1, Double>

        /// Vertical offset for superscript as em fraction (default: 0.4, positive direction)
        public var superscriptOffset: Scale<1, Double>

        public init(
            subscriptScale: Scale<1, Double> = 0.83,
            superscriptScale: Scale<1, Double> = 0.83,
            smallScale: Scale<1, Double> = 0.83,
            subscriptOffset: Scale<1, Double> = 0.2,
            superscriptOffset: Scale<1, Double> = 0.4
        ) {
            self.subscriptScale = subscriptScale
            self.superscriptScale = superscriptScale
            self.smallScale = smallScale
            self.subscriptOffset = subscriptOffset
            self.superscriptOffset = superscriptOffset
        }
    }
}
