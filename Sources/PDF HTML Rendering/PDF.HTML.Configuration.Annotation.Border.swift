// PDF.HTML.Configuration.Annotation.Border.swift
// Annotation border configuration

import ISO_32000

extension PDF.HTML.Configuration.Annotation {
    /// Annotation border configuration.
    public struct Border: Sendable, Equatable {
        /// Border width in points
        public var width: Double

        /// Border style
        public var style: ISO_32000.Border.Style.Kind

        public init(
            width: Double = 1,
            style: ISO_32000.Border.Style.Kind = .solid
        ) {
            self.width = width
            self.style = style
        }
    }
}
