import Dimension_Primitives
import PDF_Rendering
import PDF_Standard

extension PDF.UserSpace.Size where N == 1 {

    public init(
        _ absoluteSize: W3C_CSS_Fonts.AbsoluteSize,
        baseFontSize: Self
    ) {
        switch absoluteSize {
        case .xxSmall:
            self = baseFontSize * 0.6

        case .xSmall:
            self = baseFontSize * 0.75

        case .small:
            self = baseFontSize * 0.89

        case .medium:
            self = baseFontSize

        case .large:
            self = baseFontSize * 1.2

        case .xLarge:
            self = baseFontSize * 1.5

        case .xxLarge:
            self = baseFontSize * 2.0

        case .xxxLarge:
            self = baseFontSize * 3.0
        }
    }
}

extension PDF.UserSpace.Size where N == 1 {

    public init(
        _ relativeSize: W3C_CSS_Fonts.RelativeSize,
        currentSize: Self
    ) {
        switch relativeSize {
        case .smaller:
            self = currentSize / 1.2

        case .larger:
            self = currentSize * 1.2
        }
    }
}

extension PDF.UserSpace.Size where N == 1 {

    public init(
        _ lengthPercentage: LengthPercentage,
        currentSize: Self,
        baseFontSize: Self
    ) {
        switch lengthPercentage {
        case .length(let length):
            self = Self(length, currentSize: currentSize, baseFontSize: baseFontSize)

        case .percentage(let percentage):

            self = currentSize * Dimension_Primitives.Scale(percentage.value / 100.0)

        case .calc:

            self = currentSize
        }
    }
}

extension PDF.UserSpace.Size where N == 1 {

    public init(
        _ length: W3C_CSS_Values.Length,
        currentSize: Self,
        baseFontSize: Self
    ) {
        switch length {
        case .length(let value, let unit):
            switch unit {
            case .pt:
                self = Self(value)

            case .px:

                self = Self(value * 0.75)

            case .em:
                self = currentSize * Dimension_Primitives.Scale(value)

            case .rem:
                self = baseFontSize * Dimension_Primitives.Scale(value)

            case .in:
                self = Self(value * 72.0)

            case .cm:
                self = Self(value * 28.3465)

            case .mm:
                self = Self(value * 2.83465)

            case .pc:

                self = Self(value * 12.0)

            case .ex:

                self = currentSize * Dimension_Primitives.Scale(value * 0.5)

            case .ch:

                self = currentSize * Dimension_Primitives.Scale(value * 0.5)

            case .lh:

                self = currentSize * Dimension_Primitives.Scale(value * 1.2)

            case .vw, .vh, .vmin, .vmax:

                self = currentSize

            case .fr:

                self = currentSize

            case .q:

                self = Self(value * 0.70866)

            case .cap:

                self = currentSize * Dimension_Primitives.Scale(value * 0.7)

            case .ic:

                self = currentSize * Dimension_Primitives.Scale(value)

            case .rlh:

                self = baseFontSize * Dimension_Primitives.Scale(value * 1.2)
            }

        case .keyword:

            self = currentSize

        case .calc:

            self = currentSize

        case .global:
            self = currentSize
        }
    }
}
