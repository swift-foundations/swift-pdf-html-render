// W3C_CSS_Paged.PageBreakAfter+PDF.HTML.Style.Context.Modifier.swift
// CSS page-break-after property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Paged.PageBreakAfter: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        case .avoid:
            // Set flag to defer this element for sticky behavior with next element
            context.avoidPageBreakAfter = true
        case .always, .left, .right:
            // Force a page break after this element
            context.forcePageBreakAfter = true
        case .auto, .global:
            break
        }
    }
}
