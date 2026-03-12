// _Array+PDF.HTML.View.swift
// PDF rendering support for _Array (for-loops in builders)

import HTML_Renderable
import PDF_Rendering
import Rendering_Primitives

/// PDF rendering for _Array elements (for-loops in result builders).
extension Rendering._Array: PDF.HTML.View where Element: PDF.HTML.View {
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

// MARK: - Dynamic Dispatch Support

extension Rendering._Array: _ArrayContent where Element: HTML.View {
    public func _renderArrayDynamically(context: inout PDF.HTML.Context) {
        for element in elements {
            PDF.HTML.renderHTMLView(element, context: &context)
        }
    }
}
