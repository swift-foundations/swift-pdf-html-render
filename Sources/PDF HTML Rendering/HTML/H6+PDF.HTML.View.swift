// H6+PDF.HTML.View.swift
// <h6> element transformation

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension H6: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
        context.style.fontSize = configuration.headingSize(level: 6)
    }
}

extension H6: PDF.HTML.BlockMargins {
    // WebKit: margin-top: 2.33em, margin-bottom: 2.33em
    static var marginTop: LengthPercentage { .length(.em(2.33)) }
    static var marginBottom: LengthPercentage { .length(.em(2.33)) }
}
