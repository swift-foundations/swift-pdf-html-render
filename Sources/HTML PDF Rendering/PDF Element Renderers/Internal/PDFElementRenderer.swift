import PDF_Rendering

/// Protocol for types that can render specific HTML elements to PDF.
///
/// Each implementation handles one or more HTML tags and knows how to render
/// them to PDF using the provided context and configuration.
///
/// Example:
/// ```swift
/// public struct H1Renderer: PDFElementRenderer {
///     public static let supportedTags: Set<String> = ["h1"]
///
///     @MainActor
///     public static func render(
///         tag: String,
///         attributes: [String: String],
///         children: [any HTMLToPDFConvertible],
///         style: HTML.ComputedStyle,
///         context: inout PDF.Context,
///         configuration: HTML.Configuration
///     ) throws {
///         // Rendering implementation
///     }
/// }
/// ```
public protocol PDFElementRenderer: Sendable {
    /// The HTML tags this renderer handles (lowercased).
    ///
    /// Most renderers handle a single tag, but related tags may be grouped.
    static var supportedTags: Set<String> { get }

    /// Renders the HTML element to PDF.
    ///
    /// - Parameters:
    ///   - tag: The HTML tag name (lowercased)
    ///   - attributes: The element's HTML attributes
    ///   - children: Child elements to render
    ///   - style: The computed style for this element
    ///   - context: The PDF rendering context (mutated during rendering)
    ///   - configuration: The HTML-to-PDF configuration
    static func render(
        tag: String,
        attributes: [String: String],
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws
}
