// H4+PDF.HTML.View.swift
// <h4> element transformation

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension H4: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
        context.style.fontSize = configuration.headingSize(level: 4)
    }
}

extension H4: PDF.HTML.BlockMargins {
    // WebKit: margin-top: 1.33em, margin-bottom: 1.33em
    static var marginTop: LengthPercentage { .length(.em(1.33)) }
    static var marginBottom: LengthPercentage { .length(.em(1.33)) }
}
