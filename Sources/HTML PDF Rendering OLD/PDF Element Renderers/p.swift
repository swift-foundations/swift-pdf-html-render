// p.swift
// Paragraph element renderer
import PDF_Rendering
import HTML_Standard

extension Paragraph {
    /// Renderer for the `<p>` (paragraph) element.
    ///
    /// The `<p>` element represents a paragraph of text.
    /// It renders as a block with spacing after.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        let spacing = configuration.paragraphSpacing
        try renderBlock(
            children: children,
            style: style,
            context: &context,
            configuration: configuration,
            beforeSpacing: fontSize * spacing.before,
            afterSpacing: fontSize * spacing.after
        )
    }
}
