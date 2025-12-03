// strong.swift
// Strong emphasis element renderer
import PDF_Rendering
import HTML_Standard
extension StrongImportance {
    /// Renderer for the `<strong>` element.
    ///
    /// The `<strong>` element indicates strong importance.
    /// It renders as bold text without breaking inline flow.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let boldStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
        renderInline(
            children: children,
            style: boldStyle,
            context: &context,
            configuration: configuration
        )
    }
}
