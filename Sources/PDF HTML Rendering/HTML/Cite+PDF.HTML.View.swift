// Cite+PDF.HTML.View.swift
// <cite> element transformation - citation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML
import WHATWG_HTML_TextSemantics

extension WHATWG_HTML_TextSemantics.Cite: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Citations are rendered in italics (browser default)
        context.style.font = context.style.font.italic
    }
}
