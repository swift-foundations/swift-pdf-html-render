// PreformattedText+PDF.HTML.View.swift
// <pre> element transformation - preformatted text

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension PreformattedText: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Monospace font and preserve whitespace
        context.style.font = .courier
        context.preserveWhitespace = true
    }
}
