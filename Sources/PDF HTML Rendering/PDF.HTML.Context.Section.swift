// PDF.HTML.Context.Section.swift
// Section and heading tracking state

extension PDF.HTML.Context {
    /// Grouped section and heading tracking state.
    public struct Section: Sendable {
        /// Current section title (from most recent H1-H3 heading).
        public var currentTitle: String?

        /// Section titles at the start of each page (page number -> title).
        public var pageTitles: [Int: String] = [:]

        /// Collected heading entries for bookmark generation.
        public var headings: [HeadingEntry] = []

        /// Active heading capture state (non-nil when inside a heading element).
        public var activeHeading: ActiveHeading?

        /// Text buffer for heading content being rendered.
        public struct ActiveHeading: Sendable {
            public let level: Int
            public let pageNumber: Int
            public let yPosition: PDF.UserSpace.Y
            public var text: String = ""
        }

        public init() {}
    }
}
