// PDF.HTML.Configuration.Table.Border.swift
// Table border styling

import PDF_Rendering
import PDF_Standard

extension PDF.HTML.Configuration.Table {
    /// Table border styling.
    public struct Border: Sendable, Equatable {
        /// Border color
        public var color: PDF.Color

        /// Border width
        public var width: PDF.UserSpace.Size<1>

        public init(
            color: PDF.Color = .gray(0.3),
            width: PDF.UserSpace.Size<1> = 0.5
        ) {
            self.color = color
            self.width = width
        }
    }
}
