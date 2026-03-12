// PDF.HTML.Configuration.Link.swift
// Link annotation configuration

import ISO_32000

extension PDF.HTML.Configuration {
    /// Link annotation configuration.
    public struct Link: Sendable, Equatable {
        /// Visual feedback when clicking links in the PDF.
        ///
        /// - `.none`: No visual feedback
        /// - `.invert`: Invert colors in annotation rectangle (default)
        /// - `.outline`: Invert border of annotation
        /// - `.push`: Display annotation as if pressed
        public var highlightMode: ISO_32000.Annotation.Link.HighlightMode

        public init(
            highlightMode: ISO_32000.Annotation.Link.HighlightMode = .invert
        ) {
            self.highlightMode = highlightMode
        }
    }
}
