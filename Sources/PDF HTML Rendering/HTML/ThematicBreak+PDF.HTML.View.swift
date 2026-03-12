// ThematicBreak+PDF.HTML.View.swift
// <hr> element transformation - horizontal rule

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension ThematicBreak: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Flush any pending inline runs (HR is block-level)
        if context.pdf.hasInlineRuns {
            context.pdf.flush.inline()
        }

        // Add spacing before the rule
        let spacing = (context.configuration.defaultFontSize * 0.5).height
        context.pdf.advance(spacing)

        // Draw horizontal line
        let lineY = context.pdf.layoutBox.lly
        let startX = context.pdf.layoutBox.llx
        let endX = startX + context.pdf.layoutBox.width

        context.pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
            to: PDF.UserSpace.Coordinate(x: endX, y: lineY),
            color: .gray(0.5),
            width: .init(1)
        )

        // Add spacing after the rule
        context.pdf.advance(spacing)
    }
}
