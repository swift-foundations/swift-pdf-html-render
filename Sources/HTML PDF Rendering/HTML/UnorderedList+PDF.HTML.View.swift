// UnorderedList+PDF.HTML.View.swift
// <ul> element transformation - unordered list

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension UnorderedList: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Add list indentation and bullet markers
    }
}
