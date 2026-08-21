extension PDF.HTML.Context {

    public struct Link: Sendable {

        public var currentURL: String?

        public var currentInternalId: String?

        public var destinations: [String: Destination] = [:]

        public var pending: [Pending] = []

        public init() {}
    }
}
