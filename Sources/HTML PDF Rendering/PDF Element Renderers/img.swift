// img.swift
// Image element renderer

import PDF_Rendering
import HTML_Standard

extension Image {
    /// Renderer for the `<img>` element.
    ///
    /// The `<img>` element embeds an image into the document.
    /// In PDF rendering, this renders the alt text as a placeholder
    /// or embeds the actual image if available.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["img"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize

            // Flush any pending inline runs
            try context.flushInlineRuns()

            // Get image attributes
            let alt = attributes["alt"] ?? "[Image]"
            let width = attributes["width"].flatMap { Double($0) }
            let height = attributes["height"].flatMap { Double($0) }

            // Check page break
            let imageHeight = height ?? fontSize * 2
            context.checkPageBreak(needing: imageHeight)

            // For now, render as placeholder with alt text
            // Future: Load and embed actual image
            let placeholderStyle = style.merging(HTML.ComputedStyle(
                color: .gray50,
                fontStyle: .italic
            ))

            let placeholderRun = PDF.TextRun(
                text: "[\(alt)]",
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
}
