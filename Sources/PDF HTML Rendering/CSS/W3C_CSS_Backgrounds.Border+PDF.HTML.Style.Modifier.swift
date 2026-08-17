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
                pdfBorderWidth(
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
