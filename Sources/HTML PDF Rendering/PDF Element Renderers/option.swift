// option.swift
// Option element renderer

import PDF_Rendering
import HTML_Standard

extension Option {
    /// Renders the `<option>` element to PDF.
    ///
    /// The `<option>` element represents an option in a select.
    /// In PDF rendering, options are rendered as inline content.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        // Render option content inline
        // TODO: Handle selected state via computed style or other mechanism
        renderInline(
            children: children,
            style: style,
            context: &context,
            configuration: configuration
        )
    }
}
