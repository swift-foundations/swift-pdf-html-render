// u.swift
// Underline element renderer

import PDF_Rendering
import HTML_Standard

extension UnarticulatedAnnotation {
    /// Renderer for the `<u>` (underline) element.
    ///
    /// The `<u>` element represents text with an unarticulated, though explicitly
    /// rendered, non-textual annotation. It renders as underlined text.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["u"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let underlineStyle = style.merging(HTML.ComputedStyle(textDecoration: .underline))
            renderInline(
                children: children,
                style: underlineStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
