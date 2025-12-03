// td.swift
// Table data cell element renderer

import PDF_Rendering
import HTML_Standard

extension TableDataCell {
    /// Renderer for the `<td>` element.
    ///
    /// The `<td>` element defines a data cell in a table.
    /// It renders cell content with standard styling.
    /// Cell positioning is handled by the parent `<tr>` renderer.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["td"]


        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            // Render cell content inline - positioning handled by tr
            renderInline(
                children: children,
                style: style,
                context: &context,
                configuration: configuration
            )
        }
    }
}
