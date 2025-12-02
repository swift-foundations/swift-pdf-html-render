// small.swift
// Small text element renderer

import PDF_Rendering
import HTML_Standard

extension Small {
    /// Renderer for the `<small>` element.
    ///
    /// The `<small>` element represents side comments and small print.
    /// It renders at a smaller font size (typically 80% of parent).
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["small"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let smallStyle = style.merging(HTML.ComputedStyle(fontSize: fontSize * 0.8))
            renderInline(
                children: children,
                style: smallStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
