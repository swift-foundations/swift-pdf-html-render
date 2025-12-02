// HTML.swift

public import PDF_Rendering
public import HTML_Rendering

// MARK: - PDF.Document from HTML

extension PDF.Document {
    /// Create a PDF document from an HTML view using a builder closure.
    ///
    /// Example:
    /// ```swift
    /// let document = PDF.Document(
    ///     title: "My Report",
    ///     author: "Jane Doe",
    ///     configuration: .default
    /// ) {
    ///     H1 { "Hello, World!" }
    ///     Paragraph { "This is a paragraph." }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: Optional document title
    ///   - author: Optional document author
    ///   - subject: Optional document subject
    ///   - keywords: Optional document keywords
    ///   - configuration: PDF conversion configuration
    ///   - content: HTML content builder
    public init<T: HTML.View>(
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil,
        keywords: String? = nil,
        configuration: HTML.Configuration = .default,
        @HTML.Builder content: () -> T
    ) {
        let html = content()
        let pdfView = HTML.ElementMapping.convert(
            html,
            configuration: configuration,
            style: .empty
        )
        let pdfContent = renderPDFView(pdfView, configuration: configuration)

        self.init(
            title: title,
            author: author,
            subject: subject,
            keywords: keywords,
            pages: {
                PDF.Page(
                    paperSize: configuration.paperSize,
                    margins: configuration.margins,
                    content: pdfContent
                )
            }
        )
    }

    /// Create a PDF document from an existing HTML view.
    ///
    /// Example:
    /// ```swift
    /// let myHTML = ContentDivision {
    ///     H1 { "Hello" }
    /// }
    /// let document = PDF.Document(myHTML, title: "My Report")
    /// ```
    ///
    /// - Parameters:
    ///   - html: The HTML view to convert
    ///   - title: Optional document title
    ///   - author: Optional document author
    ///   - configuration: PDF conversion configuration
    public init<T: HTML.View>(
        _ html: T,
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil,
        keywords: String? = nil,
        configuration: HTML.Configuration = .default
    ) {
        let pdfView = HTML.ElementMapping.convert(
            html,
            configuration: configuration,
            style: .empty
        )
        let pdfContent = renderPDFView(pdfView, configuration: configuration)

        self.init(
            title: title,
            author: author,
            subject: subject,
            keywords: keywords,
            pages: {
                PDF.Page(
                    paperSize: configuration.paperSize,
                    margins: configuration.margins,
                    content: pdfContent
                )
            }
        )
    }
}

// MARK: - PDF View Rendering Helper

/// Render a PDF.View in a context, returning the content
private func renderPDFView(
    _ view: any PDF.View,
    configuration: HTML.Configuration
) -> PDF.Content {
    var context = PDF.Context(
        x: configuration.margins.left,
        y: configuration.margins.top,
        availableWidth: configuration.paperSize.width - configuration.margins.left - configuration.margins.right,
        availableHeight: configuration.paperSize.height - configuration.margins.top - configuration.margins.bottom,
        font: configuration.defaultFont,
        fontSize: configuration.defaultFontSize,
        color: configuration.defaultColor,
        lineHeight: configuration.lineHeight
    )

    return view.render(context: &context)
}
