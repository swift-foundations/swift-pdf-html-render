// a.swift
// Anchor (link) element renderer

import PDF_Rendering
import HTML_Standard

extension Anchor {
    /// Renders the `<a>` (anchor) element to PDF.
    ///
    /// The `<a>` element creates a hyperlink. In PDF output,
    /// it renders as clickable text with underline styling.
    /// Link URL is obtained from the inherited style's linkURL property.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        // Create link style: blue color, underline
        // The linkURL should be set via HTML._Attributes processing
        let linkStyle = style.merging(HTML.ComputedStyle(
            color: .rgb(r: 0.0, g: 0.0, b: 0.8),
            textDecoration: .underline
        ))

        // Render children with link style
        renderInline(
            children: children,
            style: linkStyle,
            context: &context,
            configuration: configuration
        )
    }
}
