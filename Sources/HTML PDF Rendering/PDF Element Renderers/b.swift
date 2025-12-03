// b.swift
// Bold element renderer
import PDF_Rendering
import HTML_Standard
extension B {
    /// Renderer for the `<b>` (bold) element.
    ///
    /// The `<b>` element draws attention to text without indicating
    /// extra importance. It renders as bold text.
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
