// figure.swift
// Figure element renderer

import PDF_Rendering
import HTML_Standard

extension Figure {
    /// Renderer for the `<figure>` element.
    ///
    /// The `<figure>` element represents self-contained content,
    /// potentially with an optional caption. It renders as a
    /// block with spacing for its contents.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["figure"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let indent = configuration.figureIndent
            let spacing = configuration.figureSpacing

            // Save current position
            let savedX = context.x
            let savedWidth = context.availableWidth

            // Apply figure indentation (centered feel)
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
