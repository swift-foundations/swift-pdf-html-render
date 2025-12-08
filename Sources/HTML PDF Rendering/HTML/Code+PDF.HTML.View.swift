// Code+PDF.HTML.View.swift
// <code> element transformation - inline code

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Code: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Switch to monospace font
        context.style.font = .courier
    }
}
