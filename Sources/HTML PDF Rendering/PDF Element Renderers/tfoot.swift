// tfoot.swift
// Table foot element renderer

import PDF_Rendering
import HTML_Standard

extension TableFoot {
    /// Renderer for the `<tfoot>` element.
    ///
    /// The `<tfoot>` element groups footer content in a table.
    /// It renders its child rows with footer styling.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["tfoot"]

        
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
                _ = HTML.renderToPDF(child, configuration: configuration, style: style, context: &context)
            }
        }
    }
}
