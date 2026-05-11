// W3C_CSS_Backgrounds.Border+PDF.HTML.Style.Modifier.swift
// CSS border shorthand to PDF context translation

public import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Backgrounds.Border: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        case .properties(let width, let style, let color):
            let baseFontSize = context.configuration.defaultFontSize
            let currentSize = context.pdf.style.fontSize

            let pdfColor: PDF.Color? = color.flatMap { PDF.Color($0) }
            let declaredWidth: PDF.UserSpace.Size<1>? = width.flatMap {
                pdfWidth(
                    from: $0,
                    currentSize: currentSize,
                    baseFontSize: baseFontSize
                )
            }
            let effectiveWidth: PDF.UserSpace.Size<1>?
            if let style, style == .none || style == .hidden {
                effectiveWidth = .init(0)
            } else {
                effectiveWidth = declaredWidth
            }

            if context.table != nil {
                if let w = effectiveWidth { context.table?.borderWidth = w }
                if let c = pdfColor { context.table?.borderColor = c }
            } else {
                if let w = effectiveWidth { context.pendingTableBorderWidth = w }
                if let c = pdfColor { context.pendingTableBorderColor = c }
            }
        case .global:
            break
        }
    }
}

// CSS `thin` / `medium` / `thick` keyword widths use the conventional 1px /
// 3px / 5px mapping. `.length(L)` delegates to the shared CSS length-to-PDF
// converter at `CSS+PDF.UserSpace.Size.swift`.
private func pdfWidth(
    from borderWidth: W3C_CSS_Backgrounds.BorderWidth,
    currentSize: PDF.UserSpace.Size<1>,
    baseFontSize: PDF.UserSpace.Size<1>
) -> PDF.UserSpace.Size<1>? {
    switch borderWidth {
    case .values(let values):
        return pdfWidth(
            fromKeyword: values.top,
            currentSize: currentSize,
            baseFontSize: baseFontSize
        )
    case .global:
        return nil
    }
}

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
