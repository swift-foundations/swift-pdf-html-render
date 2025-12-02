// hr.swift
// Horizontal rule element renderer

import PDF_Rendering
import HTML_Standard

extension ThematicBreak {
    /// Renderer for the `<hr>` (horizontal rule) element.
    ///
    /// The `<hr>` element represents a thematic break between paragraph-level
    /// elements. It renders as a horizontal line with spacing above and below.
    ///
    /// Example:
    /// ```html
    /// <p>Section one content.</p>
    /// <hr>
    /// <p>Section two content.</p>
    /// ```
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["hr"]

        
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

            // Add spacing before
            context.checkPageBreak(needing: fontSize * 0.5)
            context.advanceY(fontSize * 0.5)

            // Render horizontal line
            let lineColor = style.color ?? .gray50
            let divider = PDF.Divider(
                color: lineColor,
                thickness: 1,
                padding: 0
            )
            let lineOps = PDF.Divider._render(divider, context: &context)
            context.addOperations(lineOps.operations)

            // Add spacing after
            context.advanceY(fontSize * 0.5)
        }
    }
}
