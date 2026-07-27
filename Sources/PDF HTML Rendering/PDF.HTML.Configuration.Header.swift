// PDF.HTML.Configuration.Header.swift
// Page header configuration

import PDF_Standard

extension PDF.HTML.Configuration {
    /// Page header configuration.
    public struct Header: Sendable, Equatable {
        /// Height reserved for the header (0 for no header)
        public var height: PDF.UserSpace.Height

        public init(
            height: PDF.UserSpace.Height = .init(0)
        ) {
            self.height = height
        }
    }
}
