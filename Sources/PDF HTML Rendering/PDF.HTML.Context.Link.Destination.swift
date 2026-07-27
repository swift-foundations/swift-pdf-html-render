// PDF.HTML.Context.Link.Destination.swift
// Named destination for internal link targets

extension PDF.HTML.Context.Link {
    /// Information about a named destination (anchor target).
    public struct Destination: Sendable {
        public let pageNumber: Int
        public let yPosition: PDF.UserSpace.Y

        public init(pageNumber: Int, yPosition: PDF.UserSpace.Y) {
            self.pageNumber = pageNumber
            self.yPosition = yPosition
        }
    }
}
