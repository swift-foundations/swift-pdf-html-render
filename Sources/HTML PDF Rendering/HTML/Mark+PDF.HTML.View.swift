// Mark+PDF.HTML.View.swift
// <mark> element transformation - highlighted text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Mark: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Yellow background highlight (standard browser behavior)
        context.style.textMarkup = .highlight(PDF.Color.yellow)
    }
}
