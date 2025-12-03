// div.swift
// Division element renderer
import PDF_Rendering
import HTML_Standard
extension ContentDivision {
    /// Renderer for the `<div>` element.
    ///
    /// The `<div>` element is a generic block container.
    /// It renders as a block without additional spacing.
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
