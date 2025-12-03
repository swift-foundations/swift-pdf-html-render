// Span+Transform.swift
// <span> element transformation - inline container

import HTML_Standard
import PDF_Rendering

extension Span: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        // Span is an inline container - no style change, just pass through
        content?(context: &context, configuration: configuration)
    }
}
