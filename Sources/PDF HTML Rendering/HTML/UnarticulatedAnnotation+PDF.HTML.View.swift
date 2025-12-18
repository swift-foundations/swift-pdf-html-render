// UnarticulatedAnnotation+PDF.HTML.View.swift
// <u> element transformation - inline underline

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension UnarticulatedAnnotation: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Underline text decoration
        context.style.textMarkup = .underline
    }
}
