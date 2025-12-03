// a.swift
// Anchor (link) element renderer

import PDF_Rendering
import HTML_Standard

extension Anchor {
    /// Renderer for the `<a>` (anchor) element.
    ///
    /// The `<a>` element creates a hyperlink. In PDF output,
    /// it renders as clickable text with underline styling.
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
            // Get the href attribute for the link URL
            let href = attributes["href"]

            // Create link style: blue color, underline, and pass the URL
            var linkStyle = style.merging(HTML.ComputedStyle(
                color: .rgb(r: 0.0, g: 0.0, b: 0.8),  // Blue color for links
                textDecoration: .underline,
                linkURL: href
            ))

            // Render children with link style
            renderInline(
                children: children,
                style: linkStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
