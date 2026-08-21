import PDF_Standard

extension PDF.HTML.Configuration {

    public struct Header: Sendable, Equatable {

        public var height: PDF.UserSpace.Height

        public init(
            height: PDF.UserSpace.Height = .init(0)
        ) {
            self.height = height
        }
    }
}
