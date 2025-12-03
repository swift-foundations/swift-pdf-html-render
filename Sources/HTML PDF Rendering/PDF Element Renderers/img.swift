// img.swift
// Image element renderer

import PDF_Rendering
import HTML_Standard

extension Image {
    /// Renders the `<img>` element to PDF.
    ///
    /// The `<img>` element embeds an image into the document.
    /// In PDF rendering, this renders a placeholder.
    /// Future: Load and embed actual image from src attribute.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize

        // Flush any pending inline runs
        try context.flushInlineRuns()

        // Check page break
        let imageHeight = fontSize * 2
        context.checkPageBreak(needing: imageHeight)

        // Render as placeholder
        // TODO: Access alt/src via computed style or other mechanism
        let placeholderStyle = style.merging(HTML.ComputedStyle(
            color: .gray50,
            fontStyle: .italic
        ))
        let placeholderRun = PDF.TextRun(
            text: "[Image]",
            font: PDF.Font(placeholderStyle),
            fontSize: fontSize,
            color: placeholderStyle.color ?? .gray50
        )
        context.appendInlineRun(placeholderRun)
        try context.flushInlineRuns()

        // Add spacing after
        context.advanceY(fontSize * 0.5)
    }
}
