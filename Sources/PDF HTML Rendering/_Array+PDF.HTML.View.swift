// _Array+PDF.HTML.View.swift
// PDF rendering support for Array (for-loops in builders)

import HTML_Renderable
import PDF_Rendering
import Rendering_Primitives

/// PDF rendering for Array elements (for-loops in result builders).
extension Array: PDF.HTML.View where Element: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        for element in view {
            Element._render(element, context: &context)
        }
    }
}

// MARK: - Dynamic Dispatch Support

extension Array: _ArrayContent where Element: HTML.View {
    public func _renderArrayDynamically(context: inout PDF.HTML.Context) {
        for element in self {
            PDF.HTML.renderHTMLView(element, context: &context)
        }
    }
}
