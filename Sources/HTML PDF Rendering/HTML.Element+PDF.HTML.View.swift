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
        // Use flow-based rendering from WHATWG_HTML.Element
        switch Tag.flow {
        case .block:
            PDF.HTML.renderBlock(view.content, into: &buffer, context: &context, configuration: configuration)
        case .inline:
            PDF.HTML.renderInline(view.content, into: &buffer, context: &context, configuration: configuration)
        }
    }
}
