extension PDF.HTML.Context.Table.Grid {

    public struct Span: Sendable {

        public let originRow: Int

        public let originColumn: Int

        public let rowSpan: Int

        public let colSpan: Int

        public init(originRow: Int, originColumn: Int, rowSpan: Int, colSpan: Int) {
            self.originRow = originRow
            self.originColumn = originColumn
            self.rowSpan = rowSpan
            self.colSpan = colSpan
        }
    }
}
