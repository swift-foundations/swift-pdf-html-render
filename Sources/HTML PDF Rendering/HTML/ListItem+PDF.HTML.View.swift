// ListItem+PDF.HTML.View.swift
// <li> element transformation - list item

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension ListItem: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Add list item marker (bullet or number)
    }
}
