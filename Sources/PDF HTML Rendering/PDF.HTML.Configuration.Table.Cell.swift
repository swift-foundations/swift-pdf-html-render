// PDF.HTML.Configuration.Table.Cell.swift
// Table cell configuration

import PDF_Standard

extension PDF.HTML.Configuration.Table {
    /// Table cell configuration.
    public struct Cell: Sendable, Equatable {
        /// Padding inside table cells
        public var padding: PDF.UserSpace.Size<1>

        public init(
            padding: PDF.UserSpace.Size<1> = 4
        ) {
            self.padding = padding
        }
    }
}
