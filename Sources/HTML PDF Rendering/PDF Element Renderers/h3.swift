// h3.swift
// Level 3 heading element renderer

import PDF_Rendering
import HTML_Standard

extension H3 {
    /// Renderer for the `<h3>` heading element.
    ///
    /// The `<h3>` element represents a third-level section heading.
    /// It renders as bold text with configurable size and spacing.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["h3"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let headingSize = configuration.headingSize(level: 3)
            let spacing = configuration.headingSpacing(level: 3)
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
}
