// button.swift
// Button element renderer
import PDF_Rendering
import HTML_Standard
extension Button {
    /// Renderer for the `<button>` element.
    ///
    /// The `<button>` element represents a clickable button.
    /// In PDF rendering, it displays the button text with a simple border indication.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        // Render button with brackets to indicate it's a button
        let buttonRun = PDF.TextRun(
            text: "[ ",
            font: PDF.Font(style),
            fontSize: fontSize,
            color: style.color ?? .black
        )
        context.appendInlineRun(buttonRun)
        // Render button content
        renderInline(
            children: children,
            style: style,
            context: &context,
            configuration: configuration
        )
        let closeRun = PDF.TextRun(
            text: " ]",
            font: PDF.Font(style),
            fontSize: fontSize,
            color: style.color ?? .black
        )
        context.appendInlineRun(closeRun)
    }
}
