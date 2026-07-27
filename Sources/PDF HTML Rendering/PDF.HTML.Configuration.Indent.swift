// PDF.HTML.Configuration.Indent.swift
// Block element indentation settings

import PDF_Standard

extension PDF.HTML.Configuration {
    /// Block element indentation settings.
    public struct Indent: Sendable, Equatable {
        /// List indentation (default: 30pt)
        public var list: PDF.UserSpace.Width

        /// Blockquote indentation (default: 30pt)
        public var blockquote: PDF.UserSpace.Width

        /// Figure margin (default: 40pt)
        public var figure: PDF.UserSpace.Width

        public init(
            list: PDF.UserSpace.Width = .init(30),
            blockquote: PDF.UserSpace.Width = .init(30),
            figure: PDF.UserSpace.Width = .init(40)
        ) {
            self.list = list
            self.blockquote = blockquote
            self.figure = figure
        }
    }
}
