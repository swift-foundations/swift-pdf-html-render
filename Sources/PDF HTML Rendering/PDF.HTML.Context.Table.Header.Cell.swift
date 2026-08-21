extension PDF.HTML.Context.Table.Header {

    public struct Cell: Sendable {
        public let text: String
        public let colspan: Int

        public init(text: String, colspan: Int = 1) {
            self.text = text
            self.colspan = colspan
        }
    }
}
