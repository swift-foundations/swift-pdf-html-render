import PDF_Rendering

extension PDF.HTML.CSS {

    public struct Declaration: Sendable, Equatable {

        public var property: String

        public var value: String

        public init(property: String, value: String) {
            self.property = property
            self.value = value
        }
    }
}
