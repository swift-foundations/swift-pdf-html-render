// article.swift
// Article element renderer
import PDF_Rendering
import HTML_Standard
extension Article {
    /// Renderer for the `<article>` element.
    ///
    /// The `<article>` element represents a self-contained composition
    /// in a document. It renders as a block container.
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
