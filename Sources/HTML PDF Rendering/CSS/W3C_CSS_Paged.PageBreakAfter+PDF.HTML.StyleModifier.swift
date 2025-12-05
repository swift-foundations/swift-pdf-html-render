// PageBreakAfter+PDF.HTML.StyleModifier.swift
// CSS page-break-after property to PDF context translation

import PDF_Rendering
import PDF_Standard
import W3C_CSS_Paged

extension W3C_CSS_Paged.PageBreakAfter: PDF.HTML.HTMLContextStyleModifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        case .avoid:
            // Set flag to defer this element for sticky behavior with next element
            context.avoidPageBreakAfter = true
        case .always:
            // Force a page break after this element
            // This is handled after content rendering, not here
            break
        case .auto, .left, .right, .global:
            break
        }
    }
}
