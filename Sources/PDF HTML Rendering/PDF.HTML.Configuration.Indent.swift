import PDF_Standard

extension PDF.HTML.Configuration {

    public struct Indent: Sendable, Equatable {

        public var list: PDF.UserSpace.Width

        public var blockquote: PDF.UserSpace.Width

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
