// TableDataCell+PDF.HTML.View.swift
// <td> element transformation - table data cell with colspan/rowspan

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension TableDataCell: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TableDataCell uses default styling - handled by Table layout in HTML.Element
    }
}
