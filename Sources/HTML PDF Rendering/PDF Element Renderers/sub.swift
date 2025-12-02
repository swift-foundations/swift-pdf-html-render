// sub.swift
// Subscript element renderer

import PDF_Rendering
import HTML_Standard

extension Subscript {
    /// Renderer for the `<sub>` (subscript) element.
    ///
    /// The `<sub>` element represents subscript text.
    /// It renders at a smaller size with a vertical offset.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["sub"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let subStyle = style.merging(HTML.ComputedStyle(
                fontSize: fontSize * 0.75,
                verticalAlign: .sub
            ))
            renderInline(
                children: children,
                style: subStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
