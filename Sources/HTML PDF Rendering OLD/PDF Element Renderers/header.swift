// header.swift
// Header element renderer
import PDF_Rendering
import HTML_Standard
extension Header {
    /// Renderer for the `<header>` element.
    ///
    /// The `<header>` element represents introductory content.
    /// It renders as a block container.
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
