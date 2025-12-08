// StrongImportance+PDF.HTML.View.swift
// <strong> element transformation - inline bold

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension StrongImportance: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
    }
}
