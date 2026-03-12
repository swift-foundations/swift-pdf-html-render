// Samp+PDF.HTML.View.swift
// <samp> element transformation - sample output

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Samp: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Sample output is rendered in monospace (browser default)
        context.style.font = .courier
    }
}
