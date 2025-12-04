// HTML._Attributes+PDF.HTML.View.swift
// PDF rendering support for HTML._Attributes wrapper

import HTML_Renderable
import PDF_Rendering

/// PDF rendering for HTML._Attributes elements.
///
/// Attributes are HTML-specific metadata that don't affect PDF rendering.
/// This conformance simply passes through to render the wrapped content.
extension HTML._Attributes: PDF.HTML.View where Content: PDF.HTML.View {
    @inlinable
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // HTML attributes don't affect PDF rendering - delegate to wrapped content
        Content._render(
            view.content,
            into: &buffer,
            context: &context,
            configuration: configuration
        )
    }
}
