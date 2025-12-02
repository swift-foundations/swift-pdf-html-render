// tr.swift
// Table row element renderer

import PDF_Rendering
import HTML_Standard

extension TableRow {
    /// Renderer for the `<tr>` element.
    ///
    /// The `<tr>` element defines a row of cells in a table.
    /// It renders its child cells horizontally.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["tr"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize

            // Render row as a block with cells inline
            // TODO: Implement proper cell layout with columns
            try renderBlock(
                children: children,
                style: style,
                context: &context,
                configuration: configuration,
                afterSpacing: fontSize * 0.2
            )
        }
    }
}
