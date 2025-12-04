// P+PDF.HTML.View.swift
// <p> element transformation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Paragraph: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Paragraph uses default styling - block flow handled by HTML.Element
    }
}
