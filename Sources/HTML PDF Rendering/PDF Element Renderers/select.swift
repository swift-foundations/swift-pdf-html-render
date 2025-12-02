// select.swift
// Select element renderer

import PDF_Rendering
import HTML_Standard

extension Select {
    /// Renderer for the `<select>` element.
    ///
    /// The `<select>` element represents a control providing a menu of options.
    /// In PDF rendering, it displays as a dropdown representation.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["select"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize

            // Render select indicator
            let selectRun = PDF.TextRun(
                text: "▼ ",
                font: PDF.Font(style),
                fontSize: fontSize,
                color: style.color ?? .black
            )
            context.appendInlineRun(selectRun)

            // Render first option or placeholder
            // (Options will render themselves if present)
            renderInline(
                children: children,
                style: style,
                context: &context,
                configuration: configuration
            )
        }
    }
}
