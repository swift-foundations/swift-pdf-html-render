import ISO_32000

extension PDF.HTML.Configuration {

    public struct Link: Sendable, Equatable {

        public var highlightMode: ISO_32000.Annotation.Link.HighlightMode

        public init(
            highlightMode: ISO_32000.Annotation.Link.HighlightMode = .invert
        ) {
            self.highlightMode = highlightMode
        }
    }
}
