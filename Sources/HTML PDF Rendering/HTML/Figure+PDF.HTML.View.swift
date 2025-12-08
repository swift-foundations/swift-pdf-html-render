// Figure+PDF.HTML.View.swift
// <figure> element transformation - figure with optional caption

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Figure: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Add margin indentation for figure (browser default: 40px margins)
        let margin: PDF.UserSpace.Unit = 40
        context.layoutBox.llx = PDF.UserSpace.X(context.layoutBox.llx.value + margin)
        context.layoutBox.urx = PDF.UserSpace.X(context.layoutBox.urx.value - margin)
    }
}
