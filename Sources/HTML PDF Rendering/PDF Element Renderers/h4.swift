// h4.swift
// Level 4 heading element renderer
import PDF_Rendering
import HTML_Standard
extension H4 {
    /// Renderer for the `<h4>` heading element.
    ///
    /// The `<h4>` element represents a fourth-level section heading.
    /// It renders as bold text with configurable size and spacing.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let headingSize = configuration.headingSize(level: 4)
        let spacing = configuration.headingSpacing(level: 4)
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
