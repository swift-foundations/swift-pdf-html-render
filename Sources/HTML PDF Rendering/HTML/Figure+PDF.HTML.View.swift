// Figure+PDF.HTML.View.swift
// <figure> element transformation - figure with optional caption

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Figure: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Add margin for figure styling
    }
}
