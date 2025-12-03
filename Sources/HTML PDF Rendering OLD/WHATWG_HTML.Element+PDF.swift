// WHATWG_HTML.Element+PDF.swift
// Default PDF rendering for HTML elements

import PDF_Rendering
import HTML_Renderable
import WHATWG_HTML_Shared

/// Default PDF rendering for all WHATWG HTML elements.
///
/// Elements override this method to provide element-specific rendering.
/// The default implementation renders children as a block.
extension WHATWG_HTML.Element {
    /// Renders this element type to PDF.
    ///
    /// Override this in element-specific extensions to customize rendering.
    ///
    /// - Parameters:
    ///   - children: Child content to render
    ///   - style: The computed style for this element
    ///   - context: The PDF rendering context
    ///   - configuration: The HTML-to-PDF configuration
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        // Default: render as block
        try renderBlock(
            children: children,
            style: style,
            context: &context,
            configuration: configuration
        )
    }
}
