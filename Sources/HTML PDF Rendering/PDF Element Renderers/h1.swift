// h1.swift
// Level 1 heading element renderer

import PDF_Rendering
import HTML_Standard

extension H1 {
    /// Renderer for the `<h1>` heading element.
    ///
    /// The `<h1>` element represents the highest level section heading.
    /// It renders as bold text with configurable size and spacing.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["h1"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let headingSize = configuration.headingSize(level: 1)
            let spacing = configuration.headingSpacing(level: 1)
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
