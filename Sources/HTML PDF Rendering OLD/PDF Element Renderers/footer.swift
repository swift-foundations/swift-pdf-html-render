// footer.swift
// Footer element renderer
import PDF_Rendering
import HTML_Standard
extension Footer {
    /// Renderer for the `<footer>` element.
    ///
    /// The `<footer>` element represents a footer for its nearest
    /// sectioning content. It renders as a block container.
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
