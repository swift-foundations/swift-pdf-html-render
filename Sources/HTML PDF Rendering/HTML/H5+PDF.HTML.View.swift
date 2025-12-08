// H5+PDF.HTML.View.swift
// <h5> element transformation

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension H5: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
        context.style.fontSize = configuration.headingSize(level: 5)
    }
}

extension H5: PDF.HTML.BlockMargins {
    // WebKit: margin-top: 1.67em, margin-bottom: 1.67em
    static var marginTop: LengthPercentage { .length(.em(1.67)) }
    static var marginBottom: LengthPercentage { .length(.em(1.67)) }
}
