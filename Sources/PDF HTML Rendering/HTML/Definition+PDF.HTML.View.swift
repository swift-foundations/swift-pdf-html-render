// Definition+PDF.HTML.View.swift
// <dfn> element transformation - definition

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Definition: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Definitions are rendered in italics (browser default)
        context.style.font = context.style.font.italic
    }
}
