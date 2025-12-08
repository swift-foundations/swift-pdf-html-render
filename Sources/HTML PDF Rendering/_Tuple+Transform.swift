// _Tuple+PDF.HTML.View.swift
// Tuple renders each element in sequence

import HTML_Renderable
import PDF_Rendering
import Renderable

// MARK: - Static Dispatch (when all content conforms to PDF.HTML.View)

extension _Tuple: PDF.HTML.View where repeat each Content: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        func render<T: PDF.HTML.View>(_ element: T) {
            T._render(element, context: &context)
        }
        repeat render(each view.content)
    }
}

// MARK: - Dynamic Dispatch Support (for runtime type checking fallback)

extension _Tuple: _TupleContent where repeat each Content: HTML.View {
    public func _renderEachElementDynamically(context: inout PDF.HTML.Context) {
        func renderElement<T: HTML.View>(_ element: T) {
            PDF.HTML.renderHTMLView(element, context: &context)
        }
        repeat renderElement(each content)
    }
}
