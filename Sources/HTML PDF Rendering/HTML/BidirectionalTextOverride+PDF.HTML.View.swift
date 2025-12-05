// BidirectionalTextOverride+PDF.HTML.View.swift
// <bdo> element transformation - bidirectional text override
//
// The bdo element overrides the current directionality of text.
// No visual styling in PDF (direction handling not supported).

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML
import WHATWG_HTML_TextSemantics

extension BidirectionalTextOverride: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // BDO has no special visual styling - it's for text direction override
    }
}
