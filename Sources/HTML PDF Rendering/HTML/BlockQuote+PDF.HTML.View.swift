// BlockQuote+PDF.HTML.View.swift
// <blockquote> element transformation - block quotation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension BlockQuote: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Apply blockquote indentation (40pt left margin, standard browser default)
        let indent: PDF.UserSpace.Unit = 40
        context.x = PDF.UserSpace.X(PDF.UserSpace.Unit(context.x.value) + indent)
        context.availableWidth = PDF.UserSpace.Width(PDF.UserSpace.Unit(context.availableWidth.value) - indent)
    }
}
