// FigureCaption+PDF.HTML.View.swift
// <figcaption> element transformation - figure caption

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension FigureCaption: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Apply caption styling (smaller text, centered)
    }
}
