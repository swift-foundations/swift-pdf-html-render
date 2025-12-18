// Main+PDF.HTML.View.swift
// <main> element transformation - main content

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Main: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Main uses default styling - block flow handled by HTML.Element
    }
}
