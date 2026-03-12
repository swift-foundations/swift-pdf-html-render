// UnorderedList+PDF.HTML.View.swift
// <ul> element transformation - unordered list

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension UnorderedList: PDF.HTML.ListContainer {
    static func listType() -> PDF.Context.ListType {
        .unordered
    }
}
