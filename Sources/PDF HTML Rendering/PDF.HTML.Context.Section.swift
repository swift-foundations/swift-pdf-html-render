extension PDF.HTML.Context {

    public struct Section: Sendable {

        public var currentTitle: String?

        public var pageTitles: [Int: String] = [:]

        public var headings: [HeadingEntry] = []

        public var activeHeading: ActiveHeading?

        public init() {}
    }
}

extension PDF.HTML.Context.Section {

    public struct ActiveHeading: Sendable {
        public let level: Int
        public let pageNumber: Int
        public let yPosition: PDF.UserSpace.Y
        public var text: String = ""
    }
}
