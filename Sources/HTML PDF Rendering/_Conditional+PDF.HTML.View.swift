// _Conditional+PDF.HTML.View.swift
// PDF rendering support for _Conditional (if/else in builders)

import HTML_Renderable
import PDF_Rendering
import Renderable

/// PDF rendering for _Conditional elements (if/else branches in result builders).
extension _Conditional: PDF.HTML.View
where First: PDF.HTML.View, Second: PDF.HTML.View {
    @inlinable
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        switch view {
        case .first(let first):
            First._render(first, into: &buffer, context: &context)
        case .second(let second):
            Second._render(second, into: &buffer, context: &context)
        }
    }
}
