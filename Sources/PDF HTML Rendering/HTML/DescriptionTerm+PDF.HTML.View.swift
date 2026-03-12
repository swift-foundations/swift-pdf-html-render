// DescriptionTerm+PDF.HTML.View.swift
// <dt> element transformation - description term

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension DescriptionTerm: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.style.font = context.style.font.bold
    }
}
