// ol.swift
// Ordered list element renderer

import PDF_Rendering
import HTML_Standard

extension OrderedList {
    /// Renders the `<ol>` (ordered list) element to PDF.
    ///
    /// The `<ol>` element represents an ordered list of items.
    /// It renders as a block with numbered list items.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        let spacing = configuration.listSpacing

        // Set list style for children
        let listStyle = style.merging(HTML.ComputedStyle(listStyleType: .decimal))

        // Push list context (start at 1 by default)
        // TODO: Access start attribute via computed style or other mechanism
        context.pushList(.ordered(startNumber: 1))

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
