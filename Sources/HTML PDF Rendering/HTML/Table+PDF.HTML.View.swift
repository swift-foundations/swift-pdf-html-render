// Table+PDF.HTML.View.swift
// <table> element transformation - table

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension Table: PDF.HTML.TagRenderer, PDF.HTML.TableContainer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Table styling is handled by the table container rendering
    }
}
