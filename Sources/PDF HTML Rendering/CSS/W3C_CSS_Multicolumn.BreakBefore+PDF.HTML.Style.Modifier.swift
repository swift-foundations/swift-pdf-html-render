// W3C_CSS_Multicolumn.BreakBefore+PDF.HTML.Style.Modifier.swift
// CSS break-before property to PDF context translation
//
// The modern `break-before` property (CSS Fragmentation Module Level 3) replaces
// the legacy `page-break-before` property. This implementation maps break-before
// values to PDF page break behavior.

import PDF_Rendering

extension W3C_CSS_Multicolumn.BreakBefore: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        // Force page break values — skip if current page has no content
        case .always, .all, .page:
            guard !context.page.isEmpty else { break }
            context.page.new()

        case .left, .right, .recto, .verso:
            guard !context.page.isEmpty else { break }
            context.page.new()

        // Avoid values - try to keep with previous content
        // Similar to legacy PageBreakBefore.avoid - no action needed
        case .avoid, .avoidPage:
            break

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
