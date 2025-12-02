// mark.swift
// Mark (highlight) element renderer

import PDF_Rendering
import HTML_Standard

extension Mark {
    /// Renderer for the `<mark>` element.
    ///
    /// The `<mark>` element represents text marked or highlighted for reference
    /// or notation purposes. It renders with a yellow background.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["mark"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            // Yellow highlight color (RGB: 255, 255, 0)
            let markStyle = style.merging(HTML.ComputedStyle(backgroundColor: .rgb(r: 1.0, g: 1.0, b: 0.0)))
            renderInline(
                children: children,
                style: markStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
