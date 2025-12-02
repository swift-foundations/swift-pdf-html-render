// blockquote.swift
// Blockquote element renderer

import PDF_Rendering
import HTML_Standard

extension BlockQuote {
    /// Renderer for the `<blockquote>` element.
    ///
    /// The `<blockquote>` element represents content quoted from another source.
    /// It renders as an indented block with spacing.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["blockquote"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let indent = configuration.blockquoteIndent
            let spacing = configuration.blockquoteSpacing

            // Save current x position and width
            let savedX = context.x
            let savedWidth = context.availableWidth

            // Apply blockquote indentation
            context.x += indent
            context.availableWidth -= indent * 2

            let quoteStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))

            try renderBlock(
                children: children,
                style: quoteStyle,
                context: &context,
                configuration: configuration,
                beforeSpacing: fontSize * spacing.before,
                afterSpacing: fontSize * spacing.after
            )

            // Restore position and width
            context.x = savedX
            context.availableWidth = savedWidth
        }
    }
}
