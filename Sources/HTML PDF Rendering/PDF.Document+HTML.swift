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
    /// let doc = PDF.Document {
    ///     H1 { "Hello" }
    ///     Paragraph { "World" }
    /// }
    /// let bytes = [UInt8](doc)
    /// ```
    ///
    /// - Parameters:
    ///   - info: Document metadata (title, author, etc.)
    ///   - configuration: PDF rendering configuration
    ///   - generateOutline: If true, generates bookmarks from H1-H6 headings (default: false)
    ///   - html: The HTML content to render
    public init<H: HTML_Renderable.HTML.View>(
        info: ISO_32000.Document.Info? = nil,
        configuration: PDF.HTML.Configuration = .init(),
        generateOutline: Bool = false,
        @HTML_Renderable.HTML.Builder _ html: () -> H
    ) {
        if generateOutline {
            // Use render() to get pages and collected headings
            let result = PDF.HTML.render(
                configuration: configuration,
                html: html
            )

            // Build outline from collected headings
            // Note: HeadingEntry uses 1-indexed pageNumber, Outline.build expects 0-indexed pageIndex
            let outline = ISO_32000.Outline.build(
                from: result.headings.map { heading in
                    (
                        level: heading.level,
                        title: heading.text,
                        pageIndex: heading.pageNumber - 1,
                        yPosition: heading.yPosition
                    )
                }
            )

            // Create document with outline
            self.init(
                info: info,
                pages: result.pages,
                outline: outline.isEmpty ? nil : outline
            )
        } else {
            // Simple path without outline generation
            let pages = PDF.HTML.pages(
                configuration: configuration,
                html: html
            )

            self.init(
                info: info,
                pages: pages
            )
        }
    }
}
