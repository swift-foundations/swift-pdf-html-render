// Abbreviation+PDF.HTML.View.swift
// <abbr> element transformation - abbreviation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Abbreviation: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Abbreviations often have a dotted underline in browsers
        // For PDF, we'll use underline to indicate it's special
        context.style.textMarkup = .underline
    }
}
