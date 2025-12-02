// code.swift
// Inline code element renderer

import PDF_Rendering
import HTML_Standard

extension Code {
    /// Renderer for the `<code>` element.
    ///
    /// The `<code>` element represents a fragment of computer code.
    /// It renders in a monospace font (Courier).
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["code"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let codeStyle = style.merging(HTML.ComputedStyle(
                fontSize: fontSize * 0.9,
                fontFamily: .courier
            ))
            renderInline(
                children: children,
                style: codeStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
