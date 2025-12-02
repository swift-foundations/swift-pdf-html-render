// a.swift
// Anchor (link) element renderer

import PDF_Rendering
import HTML_Standard

extension Anchor {
    /// Renderer for the `<a>` (anchor) element.
    ///
    /// The `<a>` element creates a hyperlink. In PDF output,
    /// it renders as inline text (links are not interactive in basic PDF).
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["a"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            // Links render as inline text
            // Future: could add underline or color styling
            renderInline(
                children: children,
                style: style,
                context: &context,
                configuration: configuration
            )
        }
    }
}
