// Subscript+PDF.HTML.View.swift
// <sub> element transformation - subscript text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Subscript: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Subscript: smaller font size and lowered position
        // WebKit uses approximately 0.83em font-size and vertical-align: sub (about -0.4em)
        let currentSize = context.style.fontSize ?? 12
        context.style.fontSize = currentSize * 0.83
        // Negative verticalOffset moves text DOWN (below baseline)
        context.style.verticalOffset = (context.style.verticalOffset ?? 0) - currentSize * 0.15
    }
}
