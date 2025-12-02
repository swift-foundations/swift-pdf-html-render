// article.swift
// Article element renderer

import PDF_Rendering
import HTML_Standard

extension Article {
    /// Renderer for the `<article>` element.
    ///
    /// The `<article>` element represents a self-contained composition
    /// in a document. It renders as a block container.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["article"]

        
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
