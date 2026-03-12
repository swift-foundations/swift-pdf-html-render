// W3C_CSS_Multicolumn.BreakAfter+PDF.HTML.Style.Context.Modifier.swift
// CSS break-after property to PDF context translation
//
// The modern `break-after` property (CSS Fragmentation Module Level 3) replaces
// the legacy `page-break-after` property. This implementation maps break-after
// values to PDF page break behavior.

import PDF_Rendering
public import W3C_CSS_Multicolumn

extension W3C_CSS_Multicolumn.BreakAfter: PDF.HTML.Style.Context.Modifier {
    public func apply(to context: inout PDF.HTML.Context) {
        switch self {
        // Avoid values → sticky header behavior (keep with next element)
        case .avoid, .avoidPage:
            context.avoidPageBreakAfter = true

        // Force page break values
        case .always, .all, .page, .left, .right, .recto, .verso:
            context.forcePageBreakAfter = true

        // Column/region breaks are not applicable to PDF
        // PDF doesn't support CSS multi-column layout or regions
        case .avoidColumn, .column, .avoidRegion, .region:
            break

        // Default behavior - let layout decide
        case .auto, .global:
            break
        }
    }
}
