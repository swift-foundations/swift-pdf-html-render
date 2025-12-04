// Height+PDF.HTML.StyleModifier.swift
// CSS height property to PDF context translation

import PDF_Rendering
import PDF_Standard
import W3C_CSS_BoxModel

extension W3C_CSS_BoxModel.Height: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Apply height to PDF context
    }
}
