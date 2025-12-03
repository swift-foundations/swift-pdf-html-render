// h2.swift
// Level 2 heading element renderer
import PDF_Rendering
import HTML_Standard
extension H2 {
    /// Renderer for the `<h2>` heading element.
    ///
    /// The `<h2>` element represents a second-level section heading.
    /// It renders as bold text with configurable size and spacing.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let headingSize = configuration.headingSize(level: 2)
        let spacing = configuration.headingSpacing(level: 2)
        let headingStyle = style.merging(HTML.ComputedStyle(
            fontSize: headingSize,
            fontWeight: .bold
        ))
        try renderBlock(
            children: children,
            style: headingStyle,
            context: &context,
            configuration: configuration,
            beforeSpacing: headingSize * spacing.before,
            afterSpacing: headingSize * spacing.after
        )
    }
}
