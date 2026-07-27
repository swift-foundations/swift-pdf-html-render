// PDF.HTML.Context.Link.Pending.swift
// Pending internal link awaiting resolution

extension PDF.HTML.Context.Link {
    /// A pending internal link that needs to be resolved.
    public struct Pending: Sendable {
        public let targetId: String
        public let pageNumber: Int
        public let bounds: PDF.UserSpace.Rectangle

        public init(targetId: String, pageNumber: Int, bounds: PDF.UserSpace.Rectangle) {
            self.targetId = targetId
            self.pageNumber = pageNumber
            self.bounds = bounds
        }
    }
}
