// MarginLeft+PDF.HTML.StyleModifier.swift
// CSS margin-left property to PDF context translation

import PDF_Rendering
import PDF_Standard
import W3C_CSS_BoxModel

extension W3C_CSS_BoxModel.MarginLeft: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // TODO: Apply margin-left to PDF context
    }
}
