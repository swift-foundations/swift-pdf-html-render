// W3C_CSS_Paged.PageBreakInside+PDF.HTML.Style.Context.Modifier.swift
// CSS page-break-inside property to PDF context translation
//
// The legacy `page-break-inside` property controls whether breaks should occur
// inside an element. The `avoid` value prevents the element from splitting
// across pages.

import PDF_Rendering
public import W3C_CSS_Paged

extension W3C_CSS_Paged.PageBreakInside: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        case .avoid:
            // Prevent element from splitting across pages
            context.avoidPageBreakInside = true
        case .auto, .global:
            // Default behavior - let layout decide
            break
        }
    }
}
