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
        // Check if there are pending inline runs
        let hadContent = !context.pdf.inlineRuns.isEmpty

        // Flush any pending inline runs to render current line
        // Note: flush.inline() calls advance.line() for each rendered line
        context.pdf.flush.inline()

        // Only advance if there was no content to flush (BR at start of line)
        // If content was flushed, it already advanced to a new line
        if !hadContent {
            context.pdf.advance.line()
        }
    }
}
