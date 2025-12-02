// textarea.swift
// Textarea element renderer

import PDF_Rendering
import HTML_Standard

extension Textarea {
    /// Renderer for the `<textarea>` element.
    ///
    /// The `<textarea>` element represents a multiline text input control.
    /// In PDF rendering, it displays as a bordered text area.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["textarea"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let placeholder = attributes["placeholder"] ?? ""

            // Flush any pending inline runs
            let _ = context.flushInlineRuns()

            // Check page break
            context.checkPageBreak(needing: fontSize * 3)

            // Add spacing before
            context.advanceY(fontSize * 0.25)

            // Render textarea representation
            let displayText = placeholder.isEmpty ? "[Multi-line text area]" : "[\(placeholder)]"
            let textareaRun = PDF.TextRun(
                text: displayText,
                font: PDF.Font(style),
                fontSize: fontSize,
                color: style.color ?? .gray50
            )
            context.appendInlineRun(textareaRun)
            let _ = context.flushInlineRuns()

            // Add spacing after
            context.advanceY(fontSize * 0.5)
        }
    }
}
