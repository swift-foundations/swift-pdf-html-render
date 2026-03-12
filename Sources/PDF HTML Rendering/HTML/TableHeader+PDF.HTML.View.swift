// TableHeader+PDF.HTML.View.swift
// <th> element transformation - table header cell with scope support

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension TableHeader: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Bold font for header cells
        context.style.font = context.style.font.bold
    }
}
