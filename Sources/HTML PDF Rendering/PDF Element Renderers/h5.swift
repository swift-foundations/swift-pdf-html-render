// h5.swift
// Level 5 heading element renderer

import PDF_Rendering
import HTML_Standard

extension H5 {
    /// Renderer for the `<h5>` heading element.
    ///
    /// The `<h5>` element represents a fifth-level section heading.
    /// It renders as bold text with configurable size and spacing.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["h5"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let headingSize = configuration.headingSize(level: 5)
            let spacing = configuration.headingSpacing(level: 5)
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
