// PDF.HTML.ContextStyleModifier.swift
// Style modifier protocol for HTML-level context properties

import PDF_Rendering

extension PDF.HTML {
    /// Protocol for CSS properties that need access to the full HTML rendering context.
    ///
    /// Use this for properties like `page-break-after: avoid` that need to affect
    /// the HTML-level rendering state (e.g., deferred content for sticky headers).
    public protocol ContextStyleModifier {
        /// Apply this style to the HTML rendering context.
        func apply(to context: inout PDF.HTML.Context)
    }
}
