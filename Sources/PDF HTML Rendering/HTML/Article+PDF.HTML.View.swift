// Article+PDF.HTML.View.swift
// <article> element transformation - self-contained content

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Article: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Article uses default styling - block flow handled by HTML.Element
    }
}
