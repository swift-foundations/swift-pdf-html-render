// PDF.HTML.Configuration.Footer.swift
// Page footer configuration

import PDF_Standard

extension PDF.HTML.Configuration {
    /// Page footer configuration.
    public struct Footer: Sendable, Equatable {
        /// Height reserved for the footer (0 for no footer)
        public var height: PDF.UserSpace.Height

        public init(
            height: PDF.UserSpace.Height = .init(0)
        ) {
            self.height = height
        }
    }
}
