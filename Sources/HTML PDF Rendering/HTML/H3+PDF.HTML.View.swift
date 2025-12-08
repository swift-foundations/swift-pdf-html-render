// H3+PDF.HTML.View.swift
// <h3> element transformation

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension H3: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
        context.style.fontSize = configuration.headingSize(level: 3)
    }
}

extension H3: PDF.HTML.BlockMargins {
    // WebKit: margin-top: 1em, margin-bottom: 1em
    static var marginTop: LengthPercentage { .length(.em(1.0)) }
    static var marginBottom: LengthPercentage { .length(.em(1.0)) }
}
