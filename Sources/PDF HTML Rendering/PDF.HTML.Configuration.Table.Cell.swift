import PDF_Standard

extension PDF.HTML.Configuration.Table {

    public struct Cell: Sendable, Equatable {

        public var padding: PDF.UserSpace.Size<1>

        public init(
            padding: PDF.UserSpace.Size<1> = 4
        ) {
            self.padding = padding
        }
    }
}
