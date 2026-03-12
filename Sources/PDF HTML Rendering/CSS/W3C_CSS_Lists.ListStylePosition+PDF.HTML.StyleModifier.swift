// ListStylePosition+PDF.HTML.StyleModifier.swift
// CSS list-style-position property to PDF context translation

import PDF_Rendering
import PDF_Standard
public import W3C_CSS_Lists

extension W3C_CSS_Lists.ListStylePosition: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Apply list marker position to PDF context
    }
}
