// OrderedList+PDF.HTML.View.swift
// <ol> element transformation - ordered list

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension OrderedList: PDF.HTML.ListContainer {
    static func listType() -> PDF.Context.ListType {
        .ordered(startNumber: 1)
    }
}
