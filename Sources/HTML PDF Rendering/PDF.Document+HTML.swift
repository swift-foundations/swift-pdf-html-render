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
        info: ISO_32000.Document.Info? = nil,
        configuration: PDF.HTML.Configuration = .init(),
        @HTML_Renderable.HTML.Builder _ html: () -> H
    ) {
        // Transform HTML to PDF render operations
        let (pageOperations, pageAnnotations) = PDF.HTML.pages(
            configuration: configuration,
            html: html
        )

        // Build pages from operations
        var pages: [PDF.Page] = []
        for (i, ops) in pageOperations.enumerated() {
            let annotations = i < pageAnnotations.count ? pageAnnotations[i] : []
            pages.append(
                PDF.Page(
                    mediaBox: configuration.mediaBox,
                    operations: ops,
                    annotations: annotations
                )
            )
        }

        // Create document
        self.init(
            pages: pages,
            info: info
        )
    }
}
