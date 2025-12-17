// _Array+PDF.HTML.View.swift
// PDF rendering support for _Array (for-loops in builders)

import HTML_Renderable
import PDF_Rendering
import Rendering

/// PDF rendering for _Array elements (for-loops in result builders).
extension _Array: PDF.HTML.View where Element: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        for element in view.elements {
            Element._render(element, context: &context)
        }
    }
}
