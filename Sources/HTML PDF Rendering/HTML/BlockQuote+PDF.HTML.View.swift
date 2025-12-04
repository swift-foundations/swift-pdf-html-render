// BlockQuote+PDF.HTML.View.swift
// <blockquote> element transformation - block quotation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension BlockQuote: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Add left margin/indentation for blockquote styling
    }
}
