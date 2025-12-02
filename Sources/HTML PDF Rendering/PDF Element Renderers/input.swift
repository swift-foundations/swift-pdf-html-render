// input.swift
// Input element renderer

import PDF_Rendering
import HTML_Standard

extension Input {
    /// Renderer for the `<input>` element.
    ///
    /// The `<input>` element represents a typed data field.
    /// In PDF rendering, it displays a visual representation of the input
    /// based on its type (text box, checkbox, etc.).
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["input"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let inputType = attributes["type"]?.lowercased() ?? "text"
            let value = attributes["value"] ?? ""
            let placeholder = attributes["placeholder"] ?? ""

            // Render based on input type
            let displayText: String
            switch inputType {
            case "checkbox":
                let checked = attributes["checked"] != nil
                displayText = checked ? "[x]" : "[ ]"
            case "radio":
                let checked = attributes["checked"] != nil
                displayText = checked ? "(•)" : "( )"
            case "hidden":
                // Hidden inputs don't render
                return
            case "submit", "button", "reset":
                displayText = value.isEmpty ? inputType.capitalized : value
            default:
                // Text-like inputs
                displayText = value.isEmpty ? (placeholder.isEmpty ? "[___]" : "[\(placeholder)]") : value
            }

            let inputRun = PDF.TextRun(
                text: displayText,
                font: PDF.Font(style),
                fontSize: fontSize,
                color: style.color ?? .black
            )
            context.appendInlineRun(inputRun)
        }
    }
}
