// em.swift
// Emphasis element renderer
import PDF_Rendering
import HTML_Standard
extension Emphasis {
    /// Renderer for the `<em>` (emphasis) element.
    ///
    /// The `<em>` element marks text with stress emphasis.
    /// It renders as italic text.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
        renderInline(
            children: children,
            style: italicStyle,
            context: &context,
            configuration: configuration
        )
    }
}
