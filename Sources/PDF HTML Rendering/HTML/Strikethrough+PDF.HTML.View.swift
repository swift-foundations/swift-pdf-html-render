// Strikethrough+PDF.HTML.View.swift
// <s> element transformation - inline strikethrough

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Strikethrough: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Line through text decoration
        context.style.textMarkup = .strikeOut
    }
}
