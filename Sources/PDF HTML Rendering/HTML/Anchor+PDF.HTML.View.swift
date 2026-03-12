// Anchor+PDF.HTML.View.swift
// <a> element transformation - hyperlink

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Anchor: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Links are blue and underlined (browser default)
        context.style.color = .blue
        context.style.textMarkup = .underline
    }
}
