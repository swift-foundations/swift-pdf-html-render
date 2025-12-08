// BR+PDF.HTML.View.swift
// <br> element transformation - line break

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension BR: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Flush any pending inline runs to render current line
        context.pdf.flushInlineRuns()

        // Advance to the next line
        context.pdf.advanceLine()
    }
}
