// thead.swift
// Table head element renderer
import PDF_Rendering
import HTML_Standard
extension TableHead {
    /// Renderer for the `<thead>` element.
    ///
    /// The `<thead>` element groups header content in a table.
    /// It renders its child rows with header styling.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        // Render child rows with bold styling for headers
        let headerStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
        for child in children {
            _ = HTML.renderToPDF(child, configuration: configuration, style: headerStyle, context: &context)
        }
    }
}
