// H2+PDF.HTML.View.swift
// <h2> element transformation

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension H2: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
        context.style.fontSize = configuration.headingSize(level: 2)
    }
}

extension H2: PDF.HTML.BlockMargins {
    // WebKit: margin-top: 0.83em, margin-bottom: 0.83em
    static var marginTop: LengthPercentage { .length(.em(0.83)) }
    static var marginBottom: LengthPercentage { .length(.em(0.83)) }
}
