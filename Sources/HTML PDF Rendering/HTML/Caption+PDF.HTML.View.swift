// Caption+PDF.HTML.View.swift
// <caption> element transformation - table caption

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Caption: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Captions are centered and slightly smaller - browser default styling
        context.style.font = context.style.font.bold
    }
}
