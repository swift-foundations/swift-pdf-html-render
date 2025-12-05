// Variable+PDF.HTML.View.swift
// <var> element transformation - variable

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Variable: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Variables are rendered in italics (browser default)
        context.font = context.font.italic
    }
}
