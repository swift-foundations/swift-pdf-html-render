import PDF_Rendering

extension PDF.HTML.CSS {

    public struct Stylesheet: Sendable, Equatable {

        public var rules: [Rule]

        public init(rules: [Rule] = []) {
            self.rules = rules
        }
    }
}
