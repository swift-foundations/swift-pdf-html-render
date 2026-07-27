// PDF.HTML.Configuration.Table.swift
// Table styling configuration

import PDF_Rendering

extension PDF.HTML.Configuration {
    /// Table styling configuration.
    public struct Table: Sendable, Equatable {
        /// Cell configuration
        public var cell: Cell

        /// Border styling for table cell edges
        public var border: Border

        /// Background color for table header cells (nil for transparent)
        public var headerBackground: PDF.Color?

        /// Alternating row background color (nil for no alternation)
        public var alternatingRowColor: PDF.Color?

        public init(
            cell: Cell = .init(),
            border: Border = .init(),
            headerBackground: PDF.Color? = .gray(0.9),
            alternatingRowColor: PDF.Color? = nil
        ) {
            self.cell = cell
            self.border = border
            self.headerBackground = headerBackground
            self.alternatingRowColor = alternatingRowColor
        }
    }
}
