// PDF.Content+HTML.swift
// Two-phase transformation: HTML.View → PDF.Content

import HTML_Renderable
import PDF_Rendering

// MARK: - Phase 1: Transformation via init

extension PDF.Content {
    /// Create PDF content from HTML.
    ///
    /// This initializer transforms an HTML.View hierarchy into PDF content
    /// operations using the two-phase approach:
    /// 1. Transform: HTML.View → PDF.Content (this init)
    /// 2. Render: PDF.Content uses standard PDF.View._render pattern
    ///
    /// Example:
    /// ```swift
    /// let content = PDF.Content(myHTML)
    ///
    /// // Or in a document:
    /// PDF.Document {
    ///     PDF.Page {
    ///         PDF.Content(myHTML)
    ///     }
    /// }
    /// ```
    public init<H: HTML.View>(
        _ html: H,
        configuration: PDFTransformConfiguration = .init()
    ) {
        var context = PDF.Context(
            x: 0,
            y: 0,
            availableWidth: configuration.contentWidth,
            availableHeight: configuration.contentHeight,
            font: configuration.defaultFont,
            fontSize: configuration.defaultFontSize,
            color: configuration.defaultColor,
            lineHeight: configuration.lineHeight
        )

        // Transform HTML to PDF
        PDF.transform(html, context: &context, configuration: configuration)

        // Flush any remaining inline runs
        _ = context.flushInlineRuns()

        // Collect all operations from the context
        self = PDF.Content(operations: context.currentPageOperations)
    }
}

// MARK: - PDF.Document convenience

extension PDF.Document {
    /// Create a PDF document from HTML content.
    ///
    /// Example:
    /// ```swift
    /// let doc = PDF.Document(myHTML)
    /// let bytes = [UInt8](doc)
    /// ```
    public init<H: HTML.View>(
        _ html: H,
        title: String? = nil,
        author: String? = nil,
        configuration: PDFTransformConfiguration = .init()
    ) {
        let content = PDF.Content(html, configuration: configuration)

        let page = PDF.Page(
            paperSize: configuration.paperSize,
            margins: configuration.margins,
            content: content
        )

        self.init(
            pages: [page],
            info: (title != nil || author != nil)
                ? .init(title: title, author: author)
                : nil
        )
    }
}
