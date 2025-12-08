// _Conditional+PDF.HTML.View.swift
// PDF rendering support for _Conditional (if/else in builders)

import HTML_Renderable
import PDF_Rendering
import Renderable

/// PDF rendering for _Conditional elements (if/else branches in result builders).
extension _Conditional: PDF.HTML.View
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
