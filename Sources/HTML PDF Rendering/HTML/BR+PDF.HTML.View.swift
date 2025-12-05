// BR+PDF.HTML.View.swift
// <br> element transformation - line break

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension BR: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs to render current line
        _ = context.pdf.flushInlineRuns()

        // Advance to the next line
        context.pdf.advanceLine()
    }
}
