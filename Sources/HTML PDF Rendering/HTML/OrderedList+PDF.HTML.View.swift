// OrderedList+PDF.HTML.View.swift
// <ol> element transformation - ordered list

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension OrderedList: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Add list indentation and number markers
    }
}
