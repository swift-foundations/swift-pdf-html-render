// nav.swift
// Navigation element renderer

import PDF_Rendering
import HTML_Standard

extension NavigationSection {
    /// Renderer for the `<nav>` element.
    ///
    /// The `<nav>` element represents navigation links.
    /// It renders as a block container.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["nav"]

        
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
