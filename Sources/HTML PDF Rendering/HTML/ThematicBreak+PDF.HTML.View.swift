// ThematicBreak+PDF.HTML.View.swift
// <hr> element transformation - horizontal rule

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension ThematicBreak: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs
        _ = context.pdf.flushInlineRuns()

        // Add spacing before the rule
        let spacing = context.configuration.defaultFontSize * 0.5
        context.pdf.advance(PDF.UserSpace.Y(spacing))

        // Draw horizontal line
        let lineY = context.pdf.y
        let startX = context.pdf.x
        let endX = PDF.UserSpace.X(PDF.UserSpace.Unit(context.pdf.x.value + context.pdf.availableWidth.value))

        context.pdf.add(.graphics(.line(
            from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
            to: PDF.UserSpace.Coordinate(x: endX, y: lineY),
            color: .gray(0.5),
            width: 1
        )))

        // Add spacing after the rule
        context.pdf.advance(PDF.UserSpace.Y(spacing))
    }
}
