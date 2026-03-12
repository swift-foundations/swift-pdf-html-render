// Small+PDF.HTML.View.swift
// <small> element transformation - smaller text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Small: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.fontSize = context.style.fontSize * 0.83
    }
}
