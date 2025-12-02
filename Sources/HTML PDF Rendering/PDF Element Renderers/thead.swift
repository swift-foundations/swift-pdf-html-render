// thead.swift
// Table head element renderer

import PDF_Rendering
import HTML_Standard

extension TableHead {
    /// Renderer for the `<thead>` element.
    ///
    /// The `<thead>` element groups header content in a table.
    /// It renders its child rows with header styling.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["thead"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            // Render child rows with bold styling for headers
            let headerStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
            for child in children {
                _ = HTML.renderToPDF(child, configuration: configuration, style: headerStyle, context: &context)
            }
        }
    }
}
