// Data+PDF.HTML.View.swift
// <data> element transformation - machine-readable data
//
// The data element represents its contents, along with a machine-readable
// form of those contents in the value attribute. Like <time>, it has no
// special visual styling in browsers.

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML
import WHATWG_HTML_TextSemantics

extension WHATWG_HTML_TextSemantics.Data: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Data element uses default styling (no special appearance in browsers)
    }
}
