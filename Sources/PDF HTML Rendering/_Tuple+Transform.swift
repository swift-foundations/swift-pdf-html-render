// _Tuple+PDF.HTML.View.swift
// Tuple renders each element in sequence

import HTML_Renderable
import PDF_Rendering
import Rendering_Primitives

// MARK: - Static Dispatch (when all content conforms to PDF.HTML.View)

extension Rendering._Tuple: PDF.HTML.View where repeat each Content: PDF.HTML.View {
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

extension Rendering._Tuple: _TupleContent where repeat each Content: HTML.View {
    public func _renderEachElementDynamically(context: inout PDF.HTML.Context) {
        func renderElement<T: HTML.View>(_ element: T) {
            PDF.HTML.renderHTMLView(element, context: &context)
        }
        repeat renderElement(each content)
    }

    public func _collectElements(into collection: inout [Any]) {
        func collect<T: HTML.View>(_ element: T) {
            collection.append(element)
        }
        repeat collect(each content)
    }
}
