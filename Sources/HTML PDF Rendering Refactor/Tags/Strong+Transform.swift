// Strong+Transform.swift
// <strong> element transformation - inline bold

import HTML_Standard
import PDF_Rendering

extension StrongImportance: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        // Save current font
        let previousFont = context.font

        // Apply bold
        context.font = context.font.bold

        // Transform content inline (no flush)
        content?(context: &context, configuration: configuration)

        // Restore font
        context.font = previousFont
    }
}

// Also support <b> element
extension B: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        StrongImportance._transformTag(
            content: content,
            context: &context,
            configuration: configuration
        )
    }
}
