// Section+PDF.HTML.View.swift
// <section> element transformation - generic section

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Section: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Section uses default styling - block flow handled by HTML.Element
    }
}
