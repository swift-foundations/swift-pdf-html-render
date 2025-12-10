// HTML._Attributes+PDF.HTML.View.swift
// PDF rendering support for HTML._Attributes wrapper

import HTML_Renderable
import PDF_Rendering

/// PDF rendering for HTML._Attributes elements.
///
/// Merges HTML attributes into the PDF context so they can be accessed
/// during rendering (e.g., colspan/rowspan for table cells).
extension HTML._Attributes: PDF.HTML.View where Content: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Save previous attributes and merge new ones (same pattern as HTML rendering)
        let previousAttributes = context.attributes
        defer { context.attributes = previousAttributes }

        // Merge attributes - later values override earlier ones
        context.attributes.merge(view.attributes, uniquingKeysWith: { _, new in new })

        // Render wrapped content with merged attributes available
        Content._render(view.content, context: &context)
    }
}
