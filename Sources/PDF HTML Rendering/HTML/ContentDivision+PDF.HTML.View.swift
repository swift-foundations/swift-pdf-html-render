// ContentDivision+PDF.HTML.View.swift
// <div> element transformation - block container

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension ContentDivision: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Div uses default styling - block flow handled by HTML.Element
    }
}
