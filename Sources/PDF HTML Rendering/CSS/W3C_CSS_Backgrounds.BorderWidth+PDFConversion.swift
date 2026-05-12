// W3C_CSS_Backgrounds.BorderWidth+PDFConversion.swift
// Shared conversion from CSS border-width values to PDF user-space sizes.
// Used by the per-side border modifiers and the border shorthand modifier.

import PDF_Rendering
import PDF_Standard

/// Convert a CSS `border-width` value (or its `top` slot for multi-side
/// values) to a concrete PDF user-space size. CSS `thin`/`medium`/`thick`
/// keywords use the conventional 1px / 3px / 5px mapping at 96 DPI.
/// `.length(L)` delegates to the shared CSS length-to-PDF converter at
/// `CSS+PDF.UserSpace.Size.swift`.
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
    case .thin: return .init(0.75)   // 1px @ 96 DPI
    case .medium: return .init(2.25) // 3px @ 96 DPI
    case .thick: return .init(3.75)  // 5px @ 96 DPI
    case .length(let length):
        return PDF.UserSpace.Size<1>(
            length,
            currentSize: currentSize,
            baseFontSize: baseFontSize
        )
    }
}
