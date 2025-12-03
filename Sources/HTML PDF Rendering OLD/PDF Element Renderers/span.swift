// span.swift
// Span element renderer
import PDF_Rendering
import HTML_Standard
extension ContentSpan {
    /// Renderer for the `<span>` element.
    ///
    /// The `<span>` element is a generic inline container.
    /// It renders children with the inherited style.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        renderInline(
            children: children,
            style: style,
            context: &context,
            configuration: configuration
        )
    }
}
