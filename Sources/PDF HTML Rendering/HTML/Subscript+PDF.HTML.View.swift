// Subscript+PDF.HTML.View.swift
// <sub> element transformation - subscript text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Subscript: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Subscript: smaller font size and lowered position
        // WebKit uses approximately 0.83em font-size and vertical-align: sub
        let currentSize = context.style.fontSize
        context.style.fontSize = currentSize * 0.83
        // Subscript drops below baseline - WebKit uses about 0.2em
        let offset = (currentSize * 0.2).height
        context.style.verticalOffset = context.style.verticalOffset - offset
    }
}
