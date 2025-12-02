// s.swift
// Strikethrough element renderer

import PDF_Rendering
import HTML_Standard

extension Strikethrough {
    /// Renderer for the `<s>` (strikethrough) element.
    ///
    /// The `<s>` element represents content that is no longer accurate or relevant.
    /// It renders as text with a line through it.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["s", "strike", "del"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let strikeStyle = style.merging(HTML.ComputedStyle(textDecoration: .lineThrough))
            renderInline(
                children: children,
                style: strikeStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
