// br.swift
// Line break element renderer

import PDF_Rendering
import HTML_Standard

extension BR {
    /// Renderer for the `<br>` (line break) element.
    ///
    /// The `<br>` element produces a line break in text. It flushes any
    /// accumulated inline text and advances the Y position.
    ///
    /// Example:
    /// ```html
    /// <p>First line<br>Second line</p>
    /// ```
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["br"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize

            // Flush any pending inline runs before line break
            try context.flushInlineRuns()

            // Check page break and advance
            context.checkPageBreak(needing: fontSize)
            context.advanceY(fontSize)
        }
    }
}
