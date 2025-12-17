// ForEach+PDF.HTML.View.swift
// PDF rendering support for ForEach (from Rendering module)

import HTML_Renderable
import PDF_Rendering
import Rendering

/// PDF rendering for ForEach elements.
extension ForEach: PDF.HTML.View where Content: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        _Array._render(view.content, context: &context)
    }
}
