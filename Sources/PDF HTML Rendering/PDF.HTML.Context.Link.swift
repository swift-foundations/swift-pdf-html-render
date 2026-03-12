// PDF.HTML.Context.Link.swift
// Link tracking state for HTML-to-PDF rendering

extension PDF.HTML.Context {
    /// Grouped link tracking state.
    public struct Link: Sendable {
        /// Current link URL for text being rendered inside an anchor element.
        public var currentURL: String?

        /// Current internal link target ID (without # prefix).
        public var currentInternalId: String?

        /// Named destinations for internal links (id -> page/position).
        public var destinations: [String: Destination] = [:]

        /// Pending internal links to resolve after rendering.
        public var pending: [Pending] = []

        public init() {}
    }
}
