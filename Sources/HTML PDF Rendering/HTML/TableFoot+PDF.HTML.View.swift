// TableFoot+PDF.HTML.View.swift
// <tfoot> element transformation - table foot section

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension TableFoot: PDF.HTML.TagRenderer, PDF.HTML.TableSectionContainer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TableFoot uses default styling - handled by Table layout in HTML.Element
    }
}
