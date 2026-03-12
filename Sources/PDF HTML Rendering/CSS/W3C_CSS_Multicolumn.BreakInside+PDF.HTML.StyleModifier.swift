// BreakInside+PDF.HTML.StyleModifier.swift
// CSS break-inside property to PDF context translation
//
// The modern `break-inside` property (CSS Fragmentation Module Level 3) replaces
// the legacy `page-break-inside` property. This implementation maps break-inside
// values to PDF page break behavior.

import PDF_Rendering
public import W3C_CSS_Multicolumn

extension W3C_CSS_Multicolumn.BreakInside: PDF.HTML.HTMLContextStyleModifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        // Avoid values → prevent element from splitting across pages
        case .avoid, .avoidPage:
            context.avoidPageBreakInside = true

        // Column/region breaks are not applicable to PDF
        // PDF doesn't support CSS multi-column layout or regions
        case .avoidColumn, .avoidRegion:
            break

        // Default behavior - let layout decide
        case .auto, .global:
            break
        }
    }
}
