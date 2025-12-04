// TableHeader+PDF.HTML.View.swift
// <th> element transformation - table header cell

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension TableHeader: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.font = context.font.bold
    }
}
