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

// Dynamic dispatch: Tuple element collection is provided by Rendering._TupleMarker
// conformance in swift-rendering-primitives. Phase 0 of the worklist interpreter
// uses `as? any Rendering._TupleMarker` → `_collectElements(into:)` directly.
