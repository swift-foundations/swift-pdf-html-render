// Footer+PDF.HTML.View.swift
// <footer> element transformation - footer content

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Footer: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Footer uses default styling - block flow handled by HTML.Element
    }
}
