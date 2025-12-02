// footer.swift
// Footer element renderer

import PDF_Rendering
import HTML_Standard

extension Footer {
    /// Renderer for the `<footer>` element.
    ///
    /// The `<footer>` element represents a footer for its nearest
    /// sectioning content. It renders as a block container.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["footer"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            try renderBlock(
                children: children,
                style: style,
                context: &context,
                configuration: configuration
            )
        }
    }
}
