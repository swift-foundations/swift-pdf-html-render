// HTML.Element+PDF.HTML.View.swift
// HTML.Element rendering using WHATWG_HTML.Element.flow

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension HTML.Element: PDF.HTML.View where Content: HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Helper to render based on Tag.flow
        func renderWithFlow() {
            switch Tag.flow {
            case .block:
                PDF.HTML.renderBlock(view.content, into: &buffer, context: &context, configuration: configuration)
            case .inline:
                PDF.HTML.renderInline(view.content, into: &buffer, context: &context, configuration: configuration)
            }
        }

        // Check if Tag provides custom styling
        if let tagRenderer = Tag.self as? any PDF.HTML.TagRenderer.Type {
            // Save current style
            let savedFont = context.font
            let savedFontSize = context.fontSize

            // Apply tag-specific style
            tagRenderer.applyStyle(to: &context, configuration: configuration)

            // Render with flow
            renderWithFlow()

            // Restore style
            context.font = savedFont
            context.fontSize = savedFontSize
        } else {
            // Default: just render with flow
            renderWithFlow()
        }
    }
}
