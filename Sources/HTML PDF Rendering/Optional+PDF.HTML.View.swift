// Optional+PDF.HTML.View.swift
// Optional rendering with dynamic dispatch support

import HTML_Renderable
import PDF_Rendering

// MARK: - Static Dispatch (when Wrapped conforms to PDF.HTML.View)

extension Optional: PDF.HTML.View where Wrapped: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        if let wrapped = view {
            Wrapped._render(wrapped, context: &context)
        }
    }
}

// MARK: - Dynamic Dispatch Support

extension Optional: _OptionalContent where Wrapped: HTML.View {
    public func _renderOptionalDynamically(context: inout PDF.HTML.Context) {
        if let wrapped = self {
            PDF.HTML.renderHTMLView(wrapped, context: &context)
        }
    }
}
