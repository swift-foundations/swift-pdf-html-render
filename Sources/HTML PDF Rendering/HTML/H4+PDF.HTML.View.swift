// H4+PDF.HTML.View.swift
// <h4> element transformation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension H4: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.font = context.font.bold
        context.fontSize = configuration.headingSize(level: 4)
    }
}
