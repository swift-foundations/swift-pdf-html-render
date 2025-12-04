// HTML.InlineStyle+PDF.HTML.View.swift
// PDF rendering support for HTML.InlineStyle CSS wrapper

import HTML_Renderable
import PDF_Rendering
import W3C_CSS_Shared

/// PDF rendering for HTML.InlineStyle elements.
///
/// When rendering HTML to PDF, inline styles that conform to `PDF.HTML.StyleModifier`
/// are applied to the PDF context. This enables the same `.inlineStyle(FontWeight.bold)`
/// API used for HTML to also affect PDF output.
///
/// Example:
/// ```swift
/// p { "Bold text" }
///     .inlineStyle(FontWeight.bold)  // Works for both HTML and PDF!
/// ```
extension HTML.InlineStyle: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Save current style state
        let savedFont = context.font
        let savedFontSize = context.fontSize
        let savedColor = context.color

        defer {
            // Restore style state after rendering content
            context.font = savedFont
            context.fontSize = savedFontSize
            context.color = savedColor
        }

        // Apply the style if the property conforms to StyleModifier
        if let style = view.style {
            if let modifier = style.property as? any PDF.HTML.StyleModifier {
                modifier.apply(to: &context, configuration: configuration)
            }
        }

        // Render the wrapped content
        Content._render(
            view.content,
            into: &buffer,
            context: &context,
            configuration: configuration
        )
    }
}
