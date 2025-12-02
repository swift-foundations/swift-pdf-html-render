// main_element.swift
// Main element renderer

import PDF_Rendering
import HTML_Standard

extension Main {
    /// Renderer for the `<main>` element.
    ///
    /// The `<main>` element represents the dominant content of the body.
    /// It renders as a block container.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["main"]

        
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
