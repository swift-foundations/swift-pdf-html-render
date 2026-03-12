// Aside+PDF.HTML.View.swift
// <aside> element transformation - tangential content

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Aside: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Aside uses default styling - block flow handled by HTML.Element
    }
}
