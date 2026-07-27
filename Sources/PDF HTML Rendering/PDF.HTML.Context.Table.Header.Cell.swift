// PDF.HTML.Context.Table.Header.Cell.swift
// A captured header cell for repetition on page breaks

extension PDF.HTML.Context.Table.Header {
    /// A captured header cell for repetition
    public struct Cell: Sendable {
        public let text: String
        public let colspan: Int

        public init(text: String, colspan: Int = 1) {
            self.text = text
            self.colspan = colspan
        }
    }
}
