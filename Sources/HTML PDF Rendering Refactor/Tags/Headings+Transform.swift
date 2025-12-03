// Headings+Transform.swift
// <h1> - <h6> element transformations

import HTML_Standard
import PDF_Rendering

// MARK: - H1

extension H1: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.heading(level: 1, content: content, context: &context, configuration: configuration)
    }
}

// MARK: - H2

extension H2: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.heading(level: 2, content: content, context: &context, configuration: configuration)
    }
}

// MARK: - H3

extension H3: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.heading(level: 3, content: content, context: &context, configuration: configuration)
    }
}

// MARK: - H4

extension H4: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.heading(level: 4, content: content, context: &context, configuration: configuration)
    }
}

// MARK: - H5

extension H5: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.heading(level: 5, content: content, context: &context, configuration: configuration)
    }
}

// MARK: - H6

extension H6: PDF.TagTransform {
    public static func _transformTag(
        content: PDF.Closure?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        PDF.heading(level: 6, content: content, context: &context, configuration: configuration)
    }
}

// MARK: - Shared Implementation

extension PDF {
    static func heading(
        level: Int,
        content: Closure?,
        context: inout PDF.Context,
        configuration: Transform.Configuration
    ) {
        let headingSize = configuration.headingSize(level: level)
        let spacing = headingSize * configuration.headingSpacing

        // Save current state
        let previousFont = context.font
        let previousSize = context.fontSize

        // Apply heading style
        context.font = context.font.bold
        context.fontSize = headingSize

        // Transform as block with spacing
        PDF.block(
            content: content,
            context: &context,
            configuration: configuration,
            beforeSpacing: spacing,
            afterSpacing: spacing * 0.5
        )

        // Restore state
        context.font = previousFont
        context.fontSize = previousSize
    }
}
