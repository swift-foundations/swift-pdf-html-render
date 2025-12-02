// i.swift
// Italic element renderer

import PDF_Rendering
import HTML_Standard

extension IdiomaticText {
    /// Renderer for the `<i>` (italic) element.
    ///
    /// The `<i>` element represents text in an alternate voice or mood.
    /// It renders as italic text.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["i"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
            renderInline(
                children: children,
                style: italicStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
