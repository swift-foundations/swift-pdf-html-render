// Emphasis+PDF.HTML.View.swift
// <em> element transformation - inline italic

import HTML_Renderable
import HTML_Standard
import PDF_Rendering
import WHATWG_HTML

// MARK: - Emphasis (<em>)

extension Emphasis: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.italic
    }
}
