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
    public init<H: HTML_Renderable.HTML.View>(
        _ html: H,
        title: String? = nil,
        author: String? = nil,
        configuration: PDF.HTML.Configuration = .init()
    ) {
        // Transform HTML to PDF render operations
        let (pageOperations, pageAnnotations) = PDF.HTML.pages(from: html, configuration: configuration)

        // Build pages from operations
        var pages: [PDF.Page] = []
        for (i, ops) in pageOperations.enumerated() {
            let annotations = i < pageAnnotations.count ? pageAnnotations[i] : []
            pages.append(PDF.Page(
                mediaBox: configuration.mediaBox,
                operations: ops,
                annotations: annotations
            ))
        }

        // Create document
        self.init(
            pages: pages,
            info: (title != nil || author != nil)
                ? .init(title: title, author: author)
                : nil
        )
    }
}
