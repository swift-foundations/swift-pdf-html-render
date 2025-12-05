// P+PDF.HTML.View.swift
// <p> element transformation

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Paragraph: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Paragraph uses default styling - block flow handled by HTML.Element
    }
}

extension Paragraph: PDF.HTML.BlockMargins {
    // WebKit: margin-top: 1em, margin-bottom: 1em
    static var marginTop: LengthPercentage { .length(.em(1.0)) }
    static var marginBottom: LengthPercentage { .length(.em(1.0)) }
}
