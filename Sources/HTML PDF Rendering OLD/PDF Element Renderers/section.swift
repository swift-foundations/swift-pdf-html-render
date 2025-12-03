// section.swift
// Section element renderer
import PDF_Rendering
import HTML_Standard
extension Section {
    /// Renderer for the `<section>` element.
    ///
    /// The `<section>` element represents a generic standalone section of
    /// a document. It renders as a block container.
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
