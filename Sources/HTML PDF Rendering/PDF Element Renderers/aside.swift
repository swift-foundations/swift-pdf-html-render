// aside.swift
// Aside element renderer

import PDF_Rendering
import HTML_Standard

extension Aside {
    /// Renderer for the `<aside>` element.
    ///
    /// The `<aside>` element represents content tangentially related
    /// to the content around it. It renders as a block container.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["aside"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            try renderBlock(
                children: children,
                style: style,
                context: &context,
                configuration: configuration
            )
        }
    }
}

extension Aside: @retroactive PDF.View {
    public var body: some PDF.View {
        PDF.Divider() // actual implementation here
    }
}


