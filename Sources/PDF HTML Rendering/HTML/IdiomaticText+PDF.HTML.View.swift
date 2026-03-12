// IdiomaticText+PDF.HTML.View.swift
// <i> element transformation - inline italic

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension IdiomaticText: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.italic
    }
}
