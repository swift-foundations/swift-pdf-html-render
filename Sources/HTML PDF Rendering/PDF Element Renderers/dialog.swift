// dialog.swift
// Dialog element renderer

import PDF_Rendering
import HTML_Standard

extension Dialog {
    /// Renderer for the `<dialog>` element.
    ///
    /// The `<dialog>` element represents a dialog box or other interactive
    /// component. In PDF rendering, it renders as a bordered block.
    public struct Renderer: PDFElementRenderer {
        public static let supportedTags: Set<String> = ["dialog"]

        
        public static func render(
            tag: String,
            attributes: [String: String],
            children: [any HTMLToPDFConvertible],
            style: HTML.ComputedStyle,
            context: inout PDF.Context,
            configuration: HTML.Configuration
        ) throws {
            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let padding = configuration.dialogPadding
            let spacing = configuration.dialogSpacing

            // Only render if open attribute is present (or always in PDF for visibility)
            // In PDF we'll always render since we can't have interactive hide/show

            // Save current position
            let savedX = context.x
            let savedWidth = context.availableWidth

            // Apply dialog padding
            context.x += padding
            context.availableWidth -= padding * 2

            try renderBlock(
                children: children,
                style: style,
                context: &context,
                configuration: configuration,
                beforeSpacing: fontSize * spacing.before,
                afterSpacing: fontSize * spacing.after
            )

            // Restore position
            context.x = savedX
            context.availableWidth = savedWidth
        }
    }
}
