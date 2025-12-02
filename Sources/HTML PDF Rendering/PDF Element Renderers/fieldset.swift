// fieldset.swift
// Fieldset element renderer

import PDF_Rendering
import HTML_Standard

extension FieldSet {
    /// Renderer for the `<fieldset>` element.
    ///
    /// The `<fieldset>` element represents a set of form controls grouped together.
    /// In PDF rendering, it renders as an indented block.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["fieldset"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let indent = configuration.fieldsetIndent
            let spacing = configuration.fieldsetSpacing

            // Save current position
            let savedX = context.x
            let savedWidth = context.availableWidth

            // Apply fieldset indentation
            context.x += indent
            context.availableWidth -= indent * 2

            try renderBlock(
                children: children,
                style: style,
                context: &context,
                configuration: configuration,
                beforeSpacing: fontSize * spacing.before,
                afterSpacing: fontSize * spacing.after
            )

            // Restore position
            context.x = savedX
            context.availableWidth = savedWidth
        }
    }
}
