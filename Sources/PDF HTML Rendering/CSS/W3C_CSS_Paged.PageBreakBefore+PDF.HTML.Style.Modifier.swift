// W3C_CSS_Paged.PageBreakBefore+PDF.HTML.Style.Modifier.swift
// CSS page-break-before property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Paged.PageBreakBefore: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .always:
            // Skip if current page has no content (matches browser behavior)
            guard !context.page.isEmpty else { break }
            context.page.new()

        case .auto, .avoid:
            break

        case .left, .right:
            guard !context.page.isEmpty else { break }
            context.page.new()

        case .global:
            break
        }
    }
}
