// form.swift
// Form element renderer

import PDF_Rendering
import HTML_Standard

extension Form {
    /// Renderer for the `<form>` element.
    ///
    /// The `<form>` element represents a section containing interactive
    /// controls for submitting information. In PDF rendering, it simply
    /// renders its children as a block container.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["form"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize

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
}
