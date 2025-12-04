// PageBreakAfter+PDF.HTML.StyleModifier.swift
// CSS page-break-after property to PDF context translation

import PDF_Rendering
import PDF_Standard
import W3C_CSS_Paged

extension W3C_CSS_Paged.PageBreakAfter: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Apply page break after element
    }
}
