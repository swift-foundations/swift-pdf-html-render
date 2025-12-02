// label.swift
// Label element renderer

import PDF_Rendering
import HTML_Standard

extension Label {
    /// Renderer for the `<label>` element.
    ///
    /// The `<label>` element represents a caption for an item in a user interface.
    /// In PDF rendering, it renders as inline text.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["label"]

        
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
