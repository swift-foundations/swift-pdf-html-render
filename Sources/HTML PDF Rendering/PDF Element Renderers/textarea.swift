// textarea.swift
// Textarea element renderer

import PDF_Rendering
import HTML_Standard

extension Textarea {
    /// Renders the `<textarea>` element to PDF.
    ///
    /// The `<textarea>` element represents a multiline text input control.
    /// In PDF rendering, it displays as a placeholder text area.
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
        context.checkPageBreak(needing: fontSize * 3)

        // Add spacing before
        context.advanceY(fontSize * 0.25)

        // Render textarea representation
        let textareaRun = PDF.TextRun(
            text: "[Multi-line text area]",
            font: PDF.Font(style),
            fontSize: fontSize,
            color: style.color ?? .gray50
        )
        context.appendInlineRun(textareaRun)
        try context.flushInlineRuns()

        // Add spacing after
        context.advanceY(fontSize * 0.5)
    }
}
