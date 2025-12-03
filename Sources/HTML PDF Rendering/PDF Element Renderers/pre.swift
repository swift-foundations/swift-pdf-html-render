// pre.swift
// Preformatted text element renderer

import PDF_Rendering
import HTML_Standard

extension PreformattedText {
    /// Renderer for the `<pre>` element.
    ///
    /// The `<pre>` element represents preformatted text which preserves
    /// whitespace and uses a monospace font.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["pre"]


        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let spacing = configuration.preformattedSpacing

            let preStyle = style.merging(HTML.ComputedStyle(
                fontSize: fontSize * 0.9,
                fontFamily: .courier,
                whiteSpace: .pre
            ))

            // Enable whitespace preservation for preformatted text
            let wasPreserving = context.preserveWhitespace
            context.preserveWhitespace = true

            try renderBlock(
                children: children,
                style: preStyle,
                context: &context,
                configuration: configuration,
                beforeSpacing: fontSize * spacing.before,
                afterSpacing: fontSize * spacing.after
            )

            // Restore previous whitespace mode
            context.preserveWhitespace = wasPreserving
        }
    }
}
