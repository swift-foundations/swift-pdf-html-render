// PDF.Transform.swift
// Protocol for types that can be transformed to PDF.Content

import HTML_Renderable
import PDF_Rendering

/// Protocol for types that can be transformed to PDF content.
///
/// This protocol enables static dispatch for HTML to PDF transformation,
/// following the same pattern as `Renderable` and `PDF.View`.
///
/// Types conforming to this protocol provide a `_transform` method that
/// converts the type into PDF content operations.
public protocol PDFTransform {
    /// Transform this view to PDF content operations.
    static func _transform(
        _ view: Self,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    )
}

// MARK: - Default Implementation for HTML.View types

extension PDFTransform where Self: HTML.View, Self.Content: PDFTransform {
    /// Default implementation delegates to the body's transform method.
    @inlinable
    @_disfavoredOverload
    public static func _transform(
        _ view: Self,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        Self.Content._transform(view.body, context: &context, configuration: configuration)
    }
}

// MARK: - Dynamic Dispatch Helper

extension PDF {
    /// Transform any HTML.View to PDF operations.
    ///
    /// This bridges HTML.View types that don't directly conform to PDFTransform
    /// by checking conformance at runtime and delegating to body if needed.
    public static func transform<T: HTML.View>(
        _ view: T,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        // If the type directly conforms to PDFTransform, use static dispatch
        if let transformType = T.self as? any PDFTransform.Type {
            func callTransform<V: PDFTransform>(_ type: V.Type) {
                guard let typedView = view as? V else { return }
                V._transform(typedView, context: &context, configuration: configuration)
            }
            callTransform(transformType)
            return
        }

        // Otherwise, recursively transform the body
        transform(view.body, context: &context, configuration: configuration)
    }
}

// MARK: - Typealiases for backward compatibility

extension PDF {
    /// Typealias for Transform protocol
    public typealias Transform = PDFTransform
}
