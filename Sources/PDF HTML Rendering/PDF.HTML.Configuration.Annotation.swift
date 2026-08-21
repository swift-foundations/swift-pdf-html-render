extension PDF.HTML.Configuration {

    public struct Annotation: Sendable, Equatable {

        public var border: Border

        public init(
            border: Border = .init()
        ) {
            self.border = border
        }
    }
}
