// table.swift
// Table element renderer
import PDF_Rendering
import HTML_Standard
extension Table {
    /// Renderer for the `<table>` element.
    ///
    /// The `<table>` element represents tabular data.
    /// It renders as a block with structured rows and columns.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        // Tables render as block containers
        // TODO: Implement full table layout with column widths
        try renderBlock(
            children: children,
            style: style,
            context: &context,
            configuration: configuration,
            beforeSpacing: fontSize * 0.5,
            afterSpacing: fontSize * 0.5
        )
    }
}
