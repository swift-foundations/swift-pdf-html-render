// H1+PDF.HTML.View.swift
// <h1> element transformation

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension H1: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
        context.style.fontSize = configuration.headingSize(level: 1)
    }
}

extension H1: PDF.HTML.BlockMargins {
    // WebKit: margin-top: 0.67em, margin-bottom: 0.67em
    static var marginTop: LengthPercentage { .length(.em(0.67)) }
    static var marginBottom: LengthPercentage { .length(.em(0.67)) }
}
