// PageBreakBefore+PDF.HTML.StyleModifier.swift
// CSS page-break-before property to PDF context translation

import PDF_Rendering
import PDF_Standard
public import W3C_CSS_Paged

extension W3C_CSS_Paged.PageBreakBefore: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .always:
            // Force a page break before this element
            context.startNewPage()
        case .auto, .avoid:
            // auto: let the layout decide
            // avoid: try to keep with previous content (no action needed here)
            break
        case .left, .right:
            // Left/right page breaks - for now, treat as regular page break
            context.startNewPage()
        case .global:
            // Global CSS values (inherit, initial, etc.) - use default behavior
            break
        }
    }
}
