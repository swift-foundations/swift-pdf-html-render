// W3C_CSS_Backgrounds.BorderStyle+PDF.HTML.Style.Modifier.swift
// CSS border-style property to PDF context translation

public import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Backgrounds.BorderStyle: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        guard let topStyle else { return }

        // Per CSS, `none` and `hidden` produce no visible border —
        // collapse the effective width to zero. All other line styles
        // are drawn at the current width; the PDF renderer's stroke
        // operator emits a solid line regardless of CSS line shape
        // (dotted / dashed / double / etc. fall back to solid until a
        // future dash-pattern emitter lands).
        guard topStyle == .none || topStyle == .hidden else { return }

        let zero = PDF.UserSpace.Size<1>(0)
        if context.table != nil {
            context.table?.borderWidth = zero
        } else {
            context.pendingTableBorderWidth = zero
        }
    }

    private var topStyle: W3C_CSS_Values.LineStyle? {
        switch self {
        case .all(let style),
            .verticalHorizontal(let style, _),
            .topHorizontalBottom(let style, _, _),
            .topRightBottomLeft(let style, _, _, _):
            return style

        case .global:
            return nil
        }
    }
}
