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

// Dynamic dispatch: Optional is detected by Phase 1 Mirror-based
// isOptionalType (.optional display style). The worklist extracts
// the .some value and pushes it as .render(child.value).
