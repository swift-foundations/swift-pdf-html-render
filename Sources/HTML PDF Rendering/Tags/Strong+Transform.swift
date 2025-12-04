// Strong+PDF.HTML.View.swift
// <strong> element transformation - inline bold

import HTML_Renderable
import HTML_Standard
import PDF_Rendering
import WHATWG_HTML

// MARK: - StrongImportance (<strong>)

extension StrongImportance: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        context.font = context.font.bold
    }
}
