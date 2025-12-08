// PDF.Document+HTML.swift
// Create PDF documents from HTML content

import HTML_Renderable
import PDF_Rendering
import PDF_Standard

extension PDF.Document {
    /// Create a PDF document from HTML content.
    ///
    /// Example:
    /// ```swift
    /// let doc = PDF.Document(myHTML)
    /// let bytes = [UInt8](doc)
    /// ```
    /// Create a PDF document from HTML content using static dispatch.
    public init<H: PDF.HTML.View>(
        info: ISO_32000.Document.Info? = nil,
        configuration: PDF.HTML.Configuration = .init(),
        @HTML_Renderable.HTML.Builder _ html: () -> H
    ) {
        // Transform HTML to PDF pages
        let pages = PDF.HTML.pages(
            configuration: configuration,
            html: html
        )

        // Create document
        self.init(
            info: info,
            pages: pages
        )
    }

    /// Create a PDF document from any HTML.View using dynamic dispatch.
    @_disfavoredOverload
    public init<H: HTML_Renderable.HTML.View>(
        info: ISO_32000.Document.Info? = nil,
        configuration: PDF.HTML.Configuration = .init(),
        @HTML_Renderable.HTML.Builder _ html: () -> H
    ) {
        // Transform HTML to PDF pages
        let pages = PDF.HTML.pages(
            configuration: configuration,
            html: html
        )

        // Create document
        self.init(
            info: info,
            pages: pages
        )
    }
}
