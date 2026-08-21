import PDF_Rendering

extension PDF.HTML.CSS {

    public struct Rule: Sendable, Equatable {
        public var selectors: [Selector]
        public var declarations: [Declaration]
        public var mediaContext: MediaContext

        public init(
            selectors: [Selector],
            declarations: [Declaration],
            mediaContext: MediaContext = .unconditional
        ) {
            self.selectors = selectors
            self.declarations = declarations
            self.mediaContext = mediaContext
        }
    }
}
