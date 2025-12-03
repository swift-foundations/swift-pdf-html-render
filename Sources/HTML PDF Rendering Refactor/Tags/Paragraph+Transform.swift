// Paragraph+Transform.swift
// <p> element transformation

import HTML_Standard
import PDF_Rendering

extension Paragraph: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        let spacing = context.fontSize * configuration.paragraphSpacing

        PDF.block(
            content: content,
            context: &context,
            configuration: configuration,
            beforeSpacing: spacing,
            afterSpacing: spacing
        )
    }
}

// MARK: - Block Helper for Closure

extension PDF {
    /// Transform closure content as a block element (with inline flush).
    static func block(
        content: Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration,
        beforeSpacing: Double = 0,
        afterSpacing: Double = 0
    ) {
        // Flush pending inline runs
        _ = context.flushInlineRuns()

        // Add spacing before
        if beforeSpacing > 0 {
            context.advanceY(beforeSpacing)
        }

        // Transform content
        content?(context: &context, configuration: configuration)

        // Flush inline runs from content
        _ = context.flushInlineRuns()

        // Add spacing after
        if afterSpacing > 0 {
            context.advanceY(afterSpacing)
        }
    }
}
