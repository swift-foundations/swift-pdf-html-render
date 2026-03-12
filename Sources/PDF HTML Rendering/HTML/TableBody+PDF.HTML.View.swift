// TableBody+PDF.HTML.View.swift
// <tbody> element transformation - table body section

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension TableBody: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TableBody uses default styling - handled by Table layout in HTML.Element
    }
}
