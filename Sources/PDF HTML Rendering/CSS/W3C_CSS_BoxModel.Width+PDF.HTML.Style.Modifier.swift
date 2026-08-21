import Dimension_Primitives
import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.Width: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(.percentage(let percentage)):

            context.constraint.width =
                context.layout.box.width
                * Dimension_Primitives.Scale(percentage.value / 100.0)

        case .lengthPercentage(let lp):

            let currentSize = context.style.fontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.constraint.width = size.width

        case .auto:

            context.constraint.width = nil

        case .maxContent, .minContent, .fitContent, .fitContentLength, .stretch:

            context.constraint.width = nil

        case .global:

            break
        }
    }
}
