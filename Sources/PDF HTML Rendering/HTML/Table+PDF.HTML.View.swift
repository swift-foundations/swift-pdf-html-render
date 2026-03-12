// Table+PDF.HTML.View.swift
// <table> element transformation - table with two-pass rendering

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Table: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Table styling is handled by HTML.Element table rendering
    }
}
