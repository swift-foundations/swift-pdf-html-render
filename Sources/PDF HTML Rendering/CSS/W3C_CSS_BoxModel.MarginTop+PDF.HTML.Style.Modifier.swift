import PDF_Rendering
import PDF_Standard

extension W3C_CSS_BoxModel.MarginTop: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .lengthPercentage(let lp):
            let currentSize = context.style.fontSize
            let size = PDF.UserSpace.Size<1>(
                lp,
                currentSize: currentSize,
                baseFontSize: configuration.defaultFontSize
            )
            context.margin.top = size.height

        case .auto:

            context.margin.top = nil

        case .global:

            break
        }
    }
}
