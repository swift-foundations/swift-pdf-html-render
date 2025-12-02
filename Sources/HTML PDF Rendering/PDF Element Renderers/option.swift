// option.swift
// Option element renderer

import PDF_Rendering
import HTML_Standard

extension Option {
    /// Renderer for the `<option>` element.
    ///
    /// The `<option>` element represents an option in a select, or a suggestion
    /// in a datalist. In PDF rendering, only selected options are shown.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["option"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            // Only render if selected (or first option in select)
            let isSelected = attributes["selected"] != nil

            if isSelected {
                renderInline(
                    children: children,
                    style: style,
                    context: &context,
                    configuration: configuration
                )
            }
        }
    }
}
