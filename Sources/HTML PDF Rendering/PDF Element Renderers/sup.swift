// sup.swift
// Superscript element renderer

import PDF_Rendering
import HTML_Standard

extension Superscript {
    /// Renderer for the `<sup>` (superscript) element.
    ///
    /// The `<sup>` element represents superscript text.
    /// It renders at a smaller size with a vertical offset.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["sup"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let supStyle = style.merging(HTML.ComputedStyle(
                fontSize: fontSize * 0.75,
                verticalAlign: .super
            ))
            renderInline(
                children: children,
                style: supStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
