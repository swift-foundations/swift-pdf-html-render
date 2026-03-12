// TableRow+PDF.HTML.View.swift
// <tr> element transformation - table row with cell positioning

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension TableRow: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TableRow uses default styling - handled by Table layout in HTML.Element
    }
}
