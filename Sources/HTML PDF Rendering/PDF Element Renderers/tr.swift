// tr.swift
// Table row element renderer

import PDF_Rendering
import HTML_Standard

extension TableRow {
    /// Renderer for the `<tr>` element.
    ///
    /// The `<tr>` element defines a row of cells in a table.
    /// It renders its child cells horizontally on a single line.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["tr"]


        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize

            // Render all cells inline on the same line with tab separators
            for (index, child) in children.enumerated() {
                // Add tab separator before each cell except the first
                if index > 0 {
                    let font: PDF.Font = {
                        switch (style.fontWeight, style.fontStyle) {
                        case (.bold, .italic): return .helveticaBoldOblique
                        case (.bold, _): return .helveticaBold
                        case (_, .italic): return .helveticaOblique
                        default: return .helvetica
                        }
                    }()
                    context.appendInlineRun(PDF.TextRun(
                        text: "        ",  // 8 spaces as column separator for visible separation
                        font: font,
                        fontSize: fontSize,
                        color: style.color ?? configuration.defaultColor
                    ))
                }
                _ = HTML.renderToPDF(child, configuration: configuration, style: style, context: &context)
            }

            // Flush the row and move to next line
            _ = context.flushInlineRuns()
            context.advanceY(fontSize * 0.2)
        }
    }
}
