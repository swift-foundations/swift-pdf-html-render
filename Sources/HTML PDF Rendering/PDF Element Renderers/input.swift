// input.swift
// Input element renderer

import PDF_Rendering
import HTML_Standard

extension Input {
    /// Renders the `<input>` element to PDF.
    ///
    /// The `<input>` element represents a typed data field.
    /// In PDF rendering, it displays a placeholder representation.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize

        // Render as placeholder text field
        // TODO: Access type/value via computed style or other mechanism
        let inputRun = PDF.TextRun(
            text: "[___]",
            font: PDF.Font(style),
            fontSize: fontSize,
            color: style.color ?? .black
        )
        context.appendInlineRun(inputRun)
    }
}
