import PDF_Rendering
import PDF_Standard

internal func pdfBorderWidth(
    from borderWidth: W3C_CSS_Backgrounds.BorderWidth,
    currentSize: PDF.UserSpace.Size<1>,
    baseFontSize: PDF.UserSpace.Size<1>
) -> PDF.UserSpace.Size<1>? {
    switch borderWidth {
    case .values(let values):
        return pdfBorderWidth(
            fromKeyword: values.top,
            currentSize: currentSize,
            baseFontSize: baseFontSize
        )

    case .global:
        return nil
    }
}

internal func pdfBorderWidth(
    fromKeyword keyword: W3C_CSS_Backgrounds.BorderWidth.Width,
    currentSize: PDF.UserSpace.Size<1>,
    baseFontSize: PDF.UserSpace.Size<1>
) -> PDF.UserSpace.Size<1>? {
    switch keyword {
    case .thin: return .init(0.75)
    case .medium: return .init(2.25)
    case .thick: return .init(3.75)

    case .length(let length):
        return PDF.UserSpace.Size<1>(
            length,
            currentSize: currentSize,
            baseFontSize: baseFontSize
        )
    }
}
