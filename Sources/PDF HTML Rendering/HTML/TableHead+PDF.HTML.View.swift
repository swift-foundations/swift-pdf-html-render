// TableHead+PDF.HTML.View.swift
// <thead> element transformation - table head section

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension TableHead: PDF.HTML.TagRenderer, PDF.HTML.TableSectionContainer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TableHead uses default styling - handled by Table layout in HTML.Element
    }
}
