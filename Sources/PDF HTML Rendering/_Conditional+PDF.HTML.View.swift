// _Conditional+PDF.HTML.View.swift
// PDF rendering support for _Conditional (if/else in builders)

import HTML_Renderable
import PDF_Rendering
import Rendering

/// PDF rendering for _Conditional elements (if/else branches in result builders).
extension _Conditional: PDF.HTML.View
where First: PDF.HTML.View, Second: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: PDF.HTML.Context
    ) {
        switch view {
        case .first(let first):
            First._render(first, context: context)
        case .second(let second):
            Second._render(second, context: context)
        }
    }
}

// MARK: - Dynamic Dispatch Support

extension _Conditional: _ConditionalContent where First: HTML.View, Second: HTML.View {
    public func _renderConditionalDynamically(context: PDF.HTML.Context) {
        switch self {
        case .first(let first):
            PDF.HTML.renderHTMLView(first, context: context)
        case .second(let second):
            PDF.HTML.renderHTMLView(second, context: context)
        }
    }
}
