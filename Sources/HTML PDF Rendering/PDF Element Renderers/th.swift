// th.swift
// Table header cell element renderer

import PDF_Rendering
import HTML_Standard

extension TableHeader {
    /// Renderer for the `<th>` element.
    ///
    /// The `<th>` element defines a header cell in a table.
    /// It renders as bold text, typically centered.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["th"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            // Header cells are bold by default
            let headerStyle = style.merging(HTML.ComputedStyle(
                fontWeight: .bold,
                textAlign: .center
            ))

            // Render cell content inline
            renderInline(
                children: children,
                style: headerStyle,
                context: &context,
                configuration: configuration
            )
        }
    }
}
