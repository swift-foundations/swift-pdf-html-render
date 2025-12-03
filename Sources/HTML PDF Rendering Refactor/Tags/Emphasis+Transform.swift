// Emphasis+Transform.swift
// <em> element transformation - inline italic

import HTML_Standard
import PDF_Rendering

extension Emphasis: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        // Save current font
        let previousFont = context.font

        // Apply italic
        context.font = context.font.italic

        // Transform content inline (no flush)
        content?(context: &context, configuration: configuration)

        // Restore font
        context.font = previousFont
    }
}

// Also support <i> element
extension IdiomaticText: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        Emphasis._transformTag(
            content: content,
            context: &context,
            configuration: configuration
        )
    }
}
