// HTML.Text+PDF.HTML.View.swift
// PDF rendering support for HTML.Text

import HTML_Renderable
import PDF_Rendering

/// PDF rendering for HTML.Text elements.
///
/// HTML.Text wraps a String and handles HTML escaping. For PDF rendering,
/// we simply render the underlying text content.
extension HTML.Text: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Delegate to String rendering
        String._render(view.text, context: &context)
    }
}
