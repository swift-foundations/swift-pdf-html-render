import Dimension_Primitives

extension PDF.HTML.Configuration {

    public struct Typography: Sendable, Equatable {

        public var subscriptScale: Dimension_Primitives.Scale<1, Double>

        public var superscriptScale: Dimension_Primitives.Scale<1, Double>

        public var smallScale: Dimension_Primitives.Scale<1, Double>

        public var subscriptOffset: Dimension_Primitives.Scale<1, Double>

        public var superscriptOffset: Dimension_Primitives.Scale<1, Double>

        public init(
            subscriptScale: Dimension_Primitives.Scale<1, Double> = 0.83,
            superscriptScale: Dimension_Primitives.Scale<1, Double> = 0.83,
            smallScale: Dimension_Primitives.Scale<1, Double> = 0.83,
            subscriptOffset: Dimension_Primitives.Scale<1, Double> = 0.2,
            superscriptOffset: Dimension_Primitives.Scale<1, Double> = 0.4
        ) {
            self.subscriptScale = subscriptScale
            self.superscriptScale = superscriptScale
            self.smallScale = smallScale
            self.subscriptOffset = subscriptOffset
            self.superscriptOffset = superscriptOffset
        }
    }
}
