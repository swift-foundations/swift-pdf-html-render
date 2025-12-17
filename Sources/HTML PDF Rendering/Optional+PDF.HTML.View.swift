// Optional+PDF.HTML.View.swift
// PDF rendering support for Optional (if-let in builders)

import HTML_Renderable
import PDF_Rendering
import Rendering

/// PDF rendering for Optional elements (if-let in result builders).
extension Swift.Optional: PDF.HTML.View where Wrapped: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        switch view {
        case .some(let wrapped):
            Wrapped._render(wrapped, context: &context)
        case .none:
            break
        }
    }
}
