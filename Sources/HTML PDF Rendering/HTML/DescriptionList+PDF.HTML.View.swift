// DescriptionList+PDF.HTML.View.swift
// <dl> element transformation - description list

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension DescriptionList: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // DescriptionList uses default styling - block flow handled by HTML.Element
    }
}
