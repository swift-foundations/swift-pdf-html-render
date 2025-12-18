// ContentSpan+PDF.HTML.View.swift
// <span> element transformation - inline container

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension ContentSpan: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // ContentSpan uses default styling - inline flow handled by HTML.Element
    }
}
