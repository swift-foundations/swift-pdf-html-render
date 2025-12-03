// legend.swift
// Legend element renderer
import PDF_Rendering
import HTML_Standard
extension Legend {
    /// Renderer for the `<legend>` element.
    ///
    /// The `<legend>` element represents a caption for the content of its parent fieldset.
    /// In PDF rendering, it renders as bold text.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        // Legend styling: bold
        let legendStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
        try renderBlock(
            children: children,
            style: legendStyle,
            context: &context,
            configuration: configuration,
            afterSpacing: fontSize * 0.25
        )
    }
}
