// PDF.Converted.swift

import HTML_Renderable
import PDF_Rendering

extension PDF {
    /// Type-safe wrapper for converting HTML views to PDF.
    ///
    /// `PDF.Converted` is the primary API for HTML-to-PDF conversion.
    /// It uses an init-based transformation pattern and returns a fully
    /// concrete type (no `any` type erasure).
    ///
    /// Example:
    /// ```swift
    /// let html = ContentDivision { H1 { "Title" } }
    /// let pdfView = PDF.Converted(html, configuration: .default)
    /// // Type: PDF.Converted<HTML.Element<HTML.Element<HTML.Text>>>
    /// ```
    public struct Converted<Source: HTMLToPDFConvertible>: PDF.View {
        /// The source HTML view to convert
        public let source: Source

        /// PDF conversion configuration
        public let configuration: HTML.Configuration

        /// Initial style (typically empty, styles are computed from HTML)
        public let style: HTML.ComputedStyle

        /// Create a PDF view from an HTML view.
        ///
        /// - Parameters:
        ///   - source: The HTML view to convert
        ///   - configuration: PDF conversion settings
        ///   - style: Initial computed style (default: empty)
        public init(
            _ source: Source,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle = .empty
        ) {
            self.source = source
            self.configuration = configuration
            self.style = style
        }

        public var body: Never {
            fatalError("PDF.Converted uses render() directly")
        }

        public func render(context: inout PDF.Context) -> PDF.Content {
            source.renderToPDF(
                configuration: configuration,
                style: style,
                context: &context
            )
        }
    }
}

extension PDF.Converted: Sendable where Source: Sendable {}
