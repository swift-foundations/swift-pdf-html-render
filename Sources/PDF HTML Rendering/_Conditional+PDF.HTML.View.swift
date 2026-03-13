// _Conditional+PDF.HTML.View.swift
// PDF rendering support for Conditional (if/else in builders)

import HTML_Renderable
import PDF_Rendering
import Rendering_Primitives

/// PDF rendering for Conditional elements (if/else branches in result builders).
extension Rendering.Conditional: PDF.HTML.View
where First: PDF.HTML.View, Second: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        switch view {
        case .first(let first):
            First._render(first, context: &context)
        case .second(let second):
            Second._render(second, context: &context)
        }
    }
}

// Dynamic dispatch: Conditional is detected by Phase 1 Mirror-based
// isConditionalType (enum with "first"/"second" children). The worklist
// extracts the active case and pushes it as .render(child.value).
