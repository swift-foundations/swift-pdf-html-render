// W3C_CSS_Backgrounds.BorderColor+PDF.HTML.Style.Modifier.swift
// CSS border-color property to PDF context translation

public import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Backgrounds.BorderColor: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        guard let topColor,
            let pdfColor = PDF.Color(topColor)
        else { return }

        if context.table != nil {
            context.table?.borderColor = pdfColor
        } else {
            context.pendingTableBorderColor = pdfColor
        }
    }

    private var topColor: W3C_CSS_Values.Color? {
        switch self {
        case .all(let color),
            .verticalHorizontal(let color, _),
            .topHorizontalBottom(let color, _, _),
            .topRightBottomLeft(let color, _, _, _):
            return color

        case .global:
            return nil
        }
    }
}
