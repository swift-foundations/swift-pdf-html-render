// HTML.Element+Transform.swift
// HTML.Element transformation with tag-specific dispatch

import HTML_Renderable
import PDF_Rendering
import HTML_Standard

// MARK: - HTML.Element conforms to PDF.Transform

extension HTML.Element: PDF.Transform {
    public static func _transform(
        _ view: Self,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        // Check if the Tag type has a custom transformer
        if let tagTransform = Tag.self as? any PDF.TagTransform.Type {
            // Use helper to transform with tag-specific behavior
            PDF._transformWithTag(
                tagTransform,
                content: view.content,
                context: &context,
                configuration: configuration
            )
        } else {
            // Default: transform as block element
            PDF.block(
                content: view.content,
                context: &context,
                configuration: configuration
            )
        }
    }
}

// MARK: - Tag Transform Protocol

extension PDF {
    /// Protocol for HTML tag types that customize PDF transformation.
    ///
    /// Tag types (like `Paragraph`, `StrongImportance`, etc.) conform to this
    /// to provide tag-specific transformation behavior.
    ///
    /// Example:
    /// ```swift
    /// extension Paragraph: PDF.TagTransform {
    ///     static func _transformTag(
    ///         content: PDF.Closure?,
    ///         context: inout PDF.Context,
    ///         configuration: Transform.Configuration
    ///     ) {
    ///         // Transform paragraph with spacing...
    ///     }
    /// }
    /// ```
    public protocol TagTransform {
        /// Transform this tag type to PDF.
        static func _transformTag(
            content: Closure?,
            context: inout PDF.Context,
            configuration: PDFTransformConfiguration
        )
    }

    /// Closure wrapper for passing content transformation.
    ///
    /// Avoids existential types while allowing content to be transformed later.
    public struct Closure: @unchecked Sendable {
        private let transform: (inout PDF.Context, PDFTransformConfiguration) -> Void

        public init(_ transform: @escaping (inout PDF.Context, PDFTransformConfiguration) -> Void) {
            self.transform = transform
        }

        public func callAsFunction(context: inout PDF.Context, configuration: PDFTransformConfiguration) {
            transform(&context, configuration)
        }
    }

    /// Helper to transform content with a specific tag transformer.
    static func _transformWithTag<C: HTML.View>(
        _ tagTransform: any TagTransform.Type,
        content: C?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        let closure: Closure?
        if let content {
            closure = Closure { ctx, config in
                PDF.transform(content, context: &ctx, configuration: config)
            }
        } else {
            closure = nil
        }

        tagTransform._transformTag(
            content: closure,
            context: &context,
            configuration: configuration
        )
    }
}

// MARK: - Block and Inline Helpers

extension PDF {
    /// Transform content as a block element (with inline flush).
    public static func block<C: HTML.View>(
        content: C?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration,
        beforeSpacing: Double = 0,
        afterSpacing: Double = 0
    ) {
        // Flush pending inline runs
        _ = context.flushInlineRuns()

        // Add spacing before
        if beforeSpacing > 0 {
            context.advanceY(beforeSpacing)
        }

        // Transform content
        if let content {
            transform(content, context: &context, configuration: configuration)
        }

        // Flush inline runs from content
        _ = context.flushInlineRuns()

        // Add spacing after
        if afterSpacing > 0 {
            context.advanceY(afterSpacing)
        }
    }

    /// Transform content as inline (no flush).
    public static func inline<C: HTML.View>(
        content: C?,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        if let content {
            transform(content, context: &context, configuration: configuration)
        }
    }
}
