// ol.swift
// Ordered list element renderer

import PDF_Rendering
import HTML_Standard

extension OrderedList {
    /// Renderer for the `<ol>` (ordered list) element.
    ///
    /// The `<ol>` element represents an ordered list of items.
    /// It renders as a block with numbered list items.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["ol"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let spacing = configuration.listSpacing

            // Parse start attribute
            let start = attributes["start"].flatMap { Int($0) } ?? 1

            // Set list style for children
            let listStyle = style.merging(HTML.ComputedStyle(listStyleType: .decimal))

            // Push list context
            context.pushList(.ordered(startNumber: start))

            try renderBlock(
                children: children,
                style: listStyle,
                context: &context,
                configuration: configuration,
                beforeSpacing: fontSize * spacing.before,
                afterSpacing: fontSize * spacing.after
            )

            // Pop list context
            context.popList()
        }
    }
}
