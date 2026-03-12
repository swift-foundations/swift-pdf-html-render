// Figure+PDF.HTML.View.swift
// <figure> element transformation - figure with optional caption

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Figure: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Add margin indentation for figure (browser default: 40px margins)
        let margin: PDF.UserSpace.Width = .init(40)
        context.layoutBox.llx = context.layoutBox.llx + margin
        context.layoutBox.urx = context.layoutBox.urx - margin
    }
}
