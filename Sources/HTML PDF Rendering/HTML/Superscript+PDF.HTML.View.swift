// Superscript+PDF.HTML.View.swift
// <sup> element transformation - superscript text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Superscript: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Superscript: smaller font size and raised position
        // WebKit uses approximately 0.83em font-size and vertical-align: super
        let currentSize = context.style.fontSize ?? 12
        context.style.fontSize = currentSize * 0.83
        // Superscript rises above baseline by about 0.35em of original size
        context.style.verticalOffset = (context.style.verticalOffset ?? 0) + currentSize * 0.35
    }
}
