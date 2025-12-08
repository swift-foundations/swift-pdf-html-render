// InlineQuotation+PDF.HTML.View.swift
// <q> element transformation - inline quotation

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension InlineQuotation: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Inline quotations are typically rendered with quotes
        // For PDF, we use italic to indicate quoted text
        context.style.font = context.style.font.italic
    }
}
