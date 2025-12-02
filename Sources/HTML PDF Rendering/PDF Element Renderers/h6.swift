// h6.swift
// Level 6 heading element renderer

import PDF_Rendering
import HTML_Standard

extension H6 {
    /// Renderer for the `<h6>` heading element.
    ///
    /// The `<h6>` element represents a sixth-level (lowest) section heading.
    /// It renders as bold text with configurable size and spacing.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["h6"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let headingSize = configuration.headingSize(level: 6)
            let spacing = configuration.headingSpacing(level: 6)
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
