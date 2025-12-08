// Superscript+PDF.HTML.View.swift
// <sup> element transformation - superscript text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Superscript: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Superscript is smaller and baseline-adjusted (simplified: just smaller)
        context.style.fontSize = context.style.fontSize * 0.75
    }
}
