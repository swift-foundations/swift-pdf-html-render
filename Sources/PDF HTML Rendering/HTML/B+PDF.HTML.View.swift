// B+PDF.HTML.View.swift
// <b> element transformation - inline bold (attention)

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension B: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
    }
}
