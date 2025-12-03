// caption.swift
// Table caption element renderer
import PDF_Rendering
import HTML_Standard
extension Caption {
    /// Renderer for the `<caption>` element.
    ///
    /// The `<caption>` element represents the title of a table.
    /// It renders as centered text above/below the table.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        // Caption is centered and slightly emphasized
        let captionStyle = style.merging(HTML.ComputedStyle(
            fontWeight: .bold,
            textAlign: .center
        ))
        try renderBlock(
            children: children,
            style: captionStyle,
            context: &context,
            configuration: configuration,
            beforeSpacing: fontSize * 0.25,
            afterSpacing: fontSize * 0.5
        )
    }
}
