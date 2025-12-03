// ul.swift
// Unordered list element renderer
import PDF_Rendering
import HTML_Standard
extension UnorderedList {
    /// Renderer for the `<ul>` (unordered list) element.
    ///
    /// The `<ul>` element represents an unordered list of items.
    /// It renders as a block with bullet-style list items.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        let spacing = configuration.listSpacing
        // Set list style for children
        let listStyle = style.merging(HTML.ComputedStyle(listStyleType: .disc))
        // Push list context
        context.pushList(.unordered)
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
