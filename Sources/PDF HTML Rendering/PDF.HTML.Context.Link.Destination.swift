extension PDF.HTML.Context.Link {

    public struct Destination: Sendable {
        public let pageNumber: Int
        public let yPosition: PDF.UserSpace.Y

        public init(pageNumber: Int, yPosition: PDF.UserSpace.Y) {
            self.pageNumber = pageNumber
            self.yPosition = yPosition
        }
    }
}
