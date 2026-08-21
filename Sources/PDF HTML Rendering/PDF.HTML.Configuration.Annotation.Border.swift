import ISO_32000

extension PDF.HTML.Configuration.Annotation {

    public struct Border: Sendable, Equatable {

        public var width: Double

        public var style: ISO_32000.Border.Style.Kind

        public init(
            width: Double = 1,
            style: ISO_32000.Border.Style.Kind = .solid
        ) {
            self.width = width
            self.style = style
        }
    }
}
