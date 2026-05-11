// W3C_CSS_Backgrounds.BorderWidth+PDF.HTML.Style.Modifier.swift
// CSS border-width property to PDF context translation

public import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Backgrounds.BorderWidth: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        case .values(let values):
            let baseFontSize = context.configuration.defaultFontSize
            let currentSize = context.pdf.style.fontSize
            guard let width = pdfWidth(
                fromKeyword: values.top,
                currentSize: currentSize,
                baseFontSize: baseFontSize
            ) else { return }

            if context.table != nil {
                context.table?.borderWidth = width
            } else {
                context.pendingTableBorderWidth = width
            }
        case .global:
            break
        }
    }
}

// CSS `thin` / `medium` / `thick` keyword widths map to 1 / 3 / 5 px
// per the CSS spec convention. `.length(L)` delegates to the shared
// CSS length-to-PDF converter at `CSS+PDF.UserSpace.Size.swift`.
private func pdfWidth(
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
