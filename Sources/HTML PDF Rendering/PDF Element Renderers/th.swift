// th.swift
// Table header cell element renderer
import PDF_Rendering
import HTML_Standard
extension TableHeader {
    /// Renderer for the `<th>` element.
    ///
    /// The `<th>` element defines a header cell in a table.
    /// It renders as bold text.
    /// Cell positioning is handled by the parent `<tr>` renderer.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        // Header cells are bold by default
        let headerStyle = style.merging(HTML.ComputedStyle(
            fontWeight: .bold
        ))
        // Render cell content inline - positioning handled by tr
        renderInline(
            children: children,
            style: headerStyle,
            context: &context,
            configuration: configuration
        )
    }
}
