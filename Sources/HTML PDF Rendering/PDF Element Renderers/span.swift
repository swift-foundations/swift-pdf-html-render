// span.swift
// Span element renderer

import PDF_Rendering
import HTML_Standard

extension ContentSpan {
    /// Renderer for the `<span>` element.
    ///
    /// The `<span>` element is a generic inline container.
    /// It renders children with the inherited style.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["span"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            renderInline(
                children: children,
                style: style,
                context: &context,
                configuration: configuration
            )
        }
    }
}
