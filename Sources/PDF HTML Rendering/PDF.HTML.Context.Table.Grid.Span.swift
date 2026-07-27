// PDF.HTML.Context.Table.Grid.Span.swift
// Information about a cell span occupying grid positions

extension PDF.HTML.Context.Table.Grid {
    /// Information about a cell span occupying grid positions
    public struct Span: Sendable {
        /// Row where the spanning cell originates
        public let originRow: Int
        /// Column where the spanning cell originates
        public let originColumn: Int
        /// Number of rows the cell spans
        public let rowSpan: Int
        /// Number of columns the cell spans
        public let colSpan: Int

        public init(originRow: Int, originColumn: Int, rowSpan: Int, colSpan: Int) {
            self.originRow = originRow
            self.originColumn = originColumn
            self.rowSpan = rowSpan
            self.colSpan = colSpan
        }
    }
}
