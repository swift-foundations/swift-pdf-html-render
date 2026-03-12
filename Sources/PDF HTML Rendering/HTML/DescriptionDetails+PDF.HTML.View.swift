// DescriptionDetails+PDF.HTML.View.swift
// <dd> element transformation - description details

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension DescriptionDetails: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Add left margin indentation for description details (like browser default)
        let indent: PDF.UserSpace.Width = .init(40)
        context.layoutBox.llx = context.layoutBox.llx + indent
    }
}


