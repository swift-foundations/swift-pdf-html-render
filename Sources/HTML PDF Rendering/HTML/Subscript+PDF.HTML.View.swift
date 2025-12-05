// Subscript+PDF.HTML.View.swift
// <sub> element transformation - subscript text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Subscript: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Subscript is smaller and baseline-adjusted (simplified: just smaller)
        context.fontSize = context.fontSize * 0.75
    }
}
