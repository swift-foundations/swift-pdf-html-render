// ThematicBreak+PDF.HTML.View.swift
// <hr> element transformation - horizontal rule

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension ThematicBreak: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Draw horizontal line
    }
}
