// tbody.swift
// Table body element renderer

import PDF_Rendering
import HTML_Standard

extension TableBody {
    /// Renderer for the `<tbody>` element.
    ///
    /// The `<tbody>` element groups body content in a table.
    /// It renders its child rows with standard styling.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["tbody"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            // Render child rows
            for child in children {
                _ = child.renderToPDF(configuration: configuration, style: style, context: &context)
            }
        }
    }
}
