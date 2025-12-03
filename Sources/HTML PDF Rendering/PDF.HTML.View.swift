// PDF.HTML.View.swift
// Protocol for rendering HTML to PDF

import HTML_Renderable
import PDF_Rendering
import Renderable

extension PDF.HTML {
    /// Protocol for types that can be rendered to PDF content operations.
    ///
    /// This protocol enables static dispatch for HTML to PDF rendering,
    /// following the same buffer-based pattern as `HTML.View` and `PDF.View`.
    ///
    /// The output type is `PDF.Render.Operation`, written to a buffer.
    /// The protocol uses `PDF.Context` for layout state and accepts
    /// `PDF.HTML.Configuration` for rendering settings.
    public protocol View {
        /// Render this view to PDF content operations.
        ///
        /// - Parameters:
        ///   - view: The view to render
        ///   - buffer: Buffer to append PDF operations to
        ///   - context: Mutable PDF context tracking position and state
        ///   - configuration: Configuration for HTML to PDF rendering
        static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.Context,
            configuration: PDF.HTML.Configuration
        ) where Buffer.Element == PDF.Render.Operation
    }
}

// MARK: - Default Implementation for HTML.View types

extension PDF.HTML.View where Self: HTML.View, Self.Content: PDF.HTML.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        Self.Content._render(view.body, into: &buffer, context: &context, configuration: configuration)
    }
}

// MARK: - Dynamic Dispatch Helper

extension PDF.HTML {
    /// Render any HTML.View to PDF operations.
    ///
    /// This bridges HTML.View types that don't directly conform to PDF.HTML.View
    /// by checking conformance at runtime and delegating to body if needed.
    public static func render<Buffer: RangeReplaceableCollection, T: HTML_Renderable.HTML.View>(
        _ view: T,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // If the type directly conforms to PDF.HTML.View, use static dispatch
        if let viewType = T.self as? any PDF.HTML.View.Type {
            func callRender<V: PDF.HTML.View>(_ type: V.Type) {
                guard let typedView = view as? V else { return }
                V._render(typedView, into: &buffer, context: &context, configuration: configuration)
            }
            callRender(viewType)
            return
        }

        // Otherwise, recursively render the body
        render(view.body, into: &buffer, context: &context, configuration: configuration)
    }
}
