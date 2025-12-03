// figcaption.swift
// Figure caption element renderer
import PDF_Rendering
import HTML_Standard
extension FigureCaption {
    /// Renderer for the `<figcaption>` element.
    ///
    /// The `<figcaption>` element represents a caption or legend
    /// describing the rest of the contents of its parent figure element.
    /// It renders as centered, slightly smaller italic text.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        // Caption styling: smaller, italic, centered
        let captionStyle = style.merging(HTML.ComputedStyle(
            fontSize: fontSize * 0.9,
            fontStyle: .italic,
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
