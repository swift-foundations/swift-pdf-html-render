// Header+PDF.HTML.View.swift
// <header> element transformation - introductory content

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Header: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Header uses default styling - block flow handled by HTML.Element
    }
}
