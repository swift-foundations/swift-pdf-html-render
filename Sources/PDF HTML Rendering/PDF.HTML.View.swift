// PDF.HTML.View.swift
// Static dispatch PDF rendering for HTML.View types

import HTML_Renderable
import Layout_Primitives
import Dictionary_Primitives
import PDF_Rendering
import Rendering_Primitives


// MARK: - PDF.HTML.View Protocol

extension PDF.HTML {
    /// Protocol for types that can be rendered to PDF content.
    ///
    /// This protocol enables static dispatch for HTML to PDF rendering,
    /// following the same pattern as `PDF.View` which renders directly to context.
    ///
    /// Note: This protocol does NOT extend `Renderable` because HTML types
    /// already conform to `Renderable` via `HTML.View` with different associated
    /// types (`Context == HTML.Context`, `Output == UInt8`). Having two different
    /// `Renderable` conformances would cause a conflict.
    public protocol View {
        /// Render this view to PDF content.
        ///
        /// - Parameters:
        ///   - view: The view to render
        ///   - context: Combined context with PDF layout state and configuration
        static func _render(
            _ view: Self,
            context: inout PDF.HTML.Context
        )
    }
}

// MARK: - Default Implementation for HTML.View types

extension PDF.HTML.View where Self: HTML.View, Self.Body: PDF.HTML.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        Self.Body._render(view.body, context: &context)
    }
}
