// BidirectionalIsolate+PDF.HTML.View.swift
// <bdi> element transformation - bidirectional isolate
//
// The bdi element isolates a span of text that might be formatted in a
// different direction from other text outside it. No visual styling in PDF.

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML
import WHATWG_HTML_TextSemantics

extension BidirectionalIsolate: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // BDI has no special visual styling - it's for text direction isolation
    }
}
