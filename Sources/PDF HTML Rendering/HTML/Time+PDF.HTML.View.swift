// Time+PDF.HTML.View.swift
// <time> element transformation - date/time

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML
import WHATWG_HTML_TextSemantics

extension WHATWG_HTML_TextSemantics.Time: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Time element uses default styling (no special appearance in browsers)
    }
}
