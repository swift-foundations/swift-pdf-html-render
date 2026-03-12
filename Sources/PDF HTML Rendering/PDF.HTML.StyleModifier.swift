// PDF.HTML.StyleModifier.swift
// Style modifier protocol for CSS property application

import PDF_Rendering

extension PDF.HTML {
    /// Protocol for CSS properties that can modify PDF rendering context.
    ///
    /// CSS property types conform to this protocol to define how they affect
    /// PDF rendering. This enables the same `.inlineStyle(...)` API used for
    /// HTML to also affect PDF output.
    ///
    /// Example conformance:
    /// ```swift
    /// extension FontWeight: PDF.HTML.StyleModifier {
    ///     public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
    ///         if self == .bold { context.style.font = context.style.font.bold }
    ///     }
    /// }
    /// ```
    public protocol StyleModifier {
        /// Apply this style to the PDF rendering context.
        func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration)
    }
}
