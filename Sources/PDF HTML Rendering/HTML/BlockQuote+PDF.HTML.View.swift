// BlockQuote+PDF.HTML.View.swift
// <blockquote> element transformation - block quotation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension BlockQuote: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // WebKit default margin-left for blockquote is 40px = 30pt (at 72/96 conversion)
        let indent: PDF.UserSpace.Width = .init(30)
        context.layoutBox.llx = context.layoutBox.llx + indent
    }
}
