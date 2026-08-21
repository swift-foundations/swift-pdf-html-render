import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.Height: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(let lp):
            let currentSize = context.style.fontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.constraint.height = size.height

        case .auto:

            context.constraint.height = nil

        case .maxContent, .minContent, .fitContent, .fitContentLength, .stretch:

            context.constraint.height = nil

        case .global:

            break
        }
    }
}
