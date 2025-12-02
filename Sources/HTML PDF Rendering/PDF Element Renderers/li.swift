// li.swift
// List item element renderer

import PDF_Rendering
import HTML_Standard

extension ListItem {
    /// Renderer for the `<li>` (list item) element.
    ///
    /// The `<li>` element represents a list item.
    /// It renders with the appropriate bullet or number marker.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["li"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let indent = configuration.listIndent

            // Flush any pending runs
            let _ = context.flushInlineRuns()

            // Add spacing before item
            context.checkPageBreak(needing: fontSize)

            // Get the marker from context
            let marker = context.nextListMarker()

            // Add marker as inline run
            let markerRun = PDF.TextRun(
                text: marker + " ",
                font: PDF.Font(style),
                fontSize: fontSize,
                color: style.color ?? .black
            )
            context.appendInlineRun(markerRun)

            // Save position
            let savedX = context.x
            let savedWidth = context.availableWidth

            // Indent content
            context.x += indent
            context.availableWidth -= indent

            // Render children
            for child in children {
                _ = HTML.renderToPDF(child, configuration: configuration, style: style, context: &context)
            }

            // Flush and advance
            let _ = context.flushInlineRuns()

            // Restore position
            context.x = savedX
            context.availableWidth = savedWidth
        }
    }
}
