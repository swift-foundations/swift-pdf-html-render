// PDF.HTML.View.swift
// Static dispatch PDF rendering for HTML.View types

import HTML_Renderable
import PDF_Rendering
import Renderable

// MARK: - Context combining PDF.Context and Configuration

extension PDF.HTML {
    /// Combined context for HTML to PDF rendering.
    ///
    /// This product type bundles `PDF.Context` (mutable layout state) with
    /// `PDF.HTML.Configuration` (immutable rendering settings), providing
    /// a single context parameter for the render method.
    public struct Context {
        /// The mutable PDF layout context (position, font, page state, etc.)
        public var pdf: PDF.Context

        /// The immutable rendering configuration
        public let configuration: PDF.HTML.Configuration

        public init(pdf: PDF.Context, configuration: PDF.HTML.Configuration) {
            self.pdf = pdf
            self.configuration = configuration
        }
    }
}

// MARK: - PDF.HTML.View Protocol

extension PDF.HTML {
    /// Protocol for types that can be rendered to PDF content operations.
    ///
    /// This protocol enables static dispatch for HTML to PDF rendering,
    /// following the same buffer-based pattern as `HTML.View` and `PDF.View`.
    ///
    /// Note: This protocol does NOT extend `Renderable` because HTML types
    /// already conform to `Renderable` via `HTML.View` with different associated
    /// types (`Context == HTML.Context`, `Output == UInt8`). Having two different
    /// `Renderable` conformances would cause a conflict.
    public protocol View {
        /// Render this view to PDF content operations.
        ///
        /// - Parameters:
        ///   - view: The view to render
        ///   - buffer: Buffer to append PDF operations to
        ///   - context: Combined context with PDF layout state and configuration
        static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.HTML.Context
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
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        Self.Content._render(view.body, into: &buffer, context: &context)
    }
}
