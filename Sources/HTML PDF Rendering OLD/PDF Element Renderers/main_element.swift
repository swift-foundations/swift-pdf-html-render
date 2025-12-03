// main_element.swift
// Main element renderer
import PDF_Rendering
import HTML_Standard
extension Main {
    /// Renderer for the `<main>` element.
    ///
    /// The `<main>` element represents the dominant content of the body.
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
