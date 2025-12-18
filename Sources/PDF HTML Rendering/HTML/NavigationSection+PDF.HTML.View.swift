// NavigationSection+PDF.HTML.View.swift
// <nav> element transformation - navigation section

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension NavigationSection: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Nav uses default styling - block flow handled by HTML.Element
    }
}
