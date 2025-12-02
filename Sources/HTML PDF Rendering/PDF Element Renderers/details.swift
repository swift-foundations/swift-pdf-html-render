// details.swift
// Details disclosure element renderer

import PDF_Rendering
import HTML_Standard

extension Details {
    /// Renderer for the `<details>` element.
    ///
    /// The `<details>` element represents a disclosure widget from which
    /// the user can obtain additional information or controls.
    /// In PDF rendering, the content is always shown (expanded state).
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["details"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let indent = configuration.detailsIndent
            let spacing = configuration.detailsSpacing

            // Save current position
            let savedX = context.x
            let savedWidth = context.availableWidth

            // Apply details indentation for content (not summary)
            context.x += indent
            context.availableWidth -= indent

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
