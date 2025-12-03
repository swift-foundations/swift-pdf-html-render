// summary.swift
// Disclosure summary element renderer
import PDF_Rendering
import HTML_Standard
extension DisclosureSummary {
    /// Renderer for the `<summary>` element.
    ///
    /// The `<summary>` element represents a summary, caption, or legend
    /// for the rest of the contents of its parent details element.
    /// In PDF rendering, it shows with a disclosure indicator.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        // Flush any pending inline runs
        let _ = context.flushInlineRuns()
        // Add disclosure triangle indicator (expanded state)
        let disclosureRun = PDF.TextRun(
            text: "▼ ",
            font: PDF.Font(style),
            fontSize: fontSize,
            color: style.color ?? .black
        )
        context.appendInlineRun(disclosureRun)
        // Render summary content with bold styling
        let summaryStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
        renderInline(
            children: children,
            style: summaryStyle,
            context: &context,
            configuration: configuration
        )
        let _ = context.flushInlineRuns()
    }
}
