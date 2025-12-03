// aside.swift
// Aside element renderer

import PDF_Rendering
import HTML_Standard

extension Aside {
    /// Renders the `<aside>` element to PDF.
    ///
    /// The `<aside>` element represents content tangentially related
    /// to the content around it. It renders as a block container.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        try renderBlock(
            children: children,
            style: style,
            context: &context,
            configuration: configuration
        )
    }
}
