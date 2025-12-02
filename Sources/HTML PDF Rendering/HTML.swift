// HTML.swift

public import PDF_Rendering
public import HTML_Renderable

// MARK: - PDF.Document from HTML

extension PDF.Document {
    /// Create a PDF document from an HTML view using a builder closure.
    ///
    /// This initializer converts HTML views to PDF. The HTML content
    /// is rendered to PDF using type-safe conversion.
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
        let pdfContent = renderHTMLView(html, configuration: configuration)

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
    /// This initializer converts HTML views to PDF using type-safe conversion.
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
        let pdfContent = renderHTMLView(html, configuration: configuration)

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

// MARK: - PDF Rendering Helper

/// Render an HTML view to PDF content.
///
/// This function handles conversion of any HTML.View to PDF.Content.
/// It supports all HTML DSL types through the HTMLToPDFConvertible protocol.
private func renderHTMLView<T: HTML.View>(
    _ html: T,
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

    // Convert the HTML view to PDF content
    var operations: [PDF.Operation] = []

    let result = convertToPDF(
        html,
        configuration: configuration,
        style: .empty,
        context: &context
    )
    operations.append(contentsOf: result.operations)

    // Flush any remaining inline runs at the end
    operations.append(contentsOf: context.flushInlineRuns().operations)

    return PDF.Content(operations: operations)
}

/// Internal conversion function that handles runtime type checking.
///
/// This enables conversion of opaque `some HTML.View` types by checking
/// conformance at runtime. For custom views that don't directly conform to
/// HTMLToPDFConvertible, we recursively render their body property.
internal func convertToPDF<T: HTML.View>(
    _ view: T,
    configuration: HTML.Configuration,
    style: HTML.ComputedStyle,
    context: inout PDF.Context
) -> PDF.Content {
    // If the view directly conforms to HTMLToPDFConvertible, use it
    if let convertible = view as? any HTMLToPDFConvertible {
        return convertible.renderToPDF(
            configuration: configuration,
            style: style,
            context: &context
        )
    }

    // For custom HTML.View types, recursively render their body
    // This mirrors how HTML rendering works - delegating to body
    return convertToPDF(
        view.body,
        configuration: configuration,
        style: style,
        context: &context
    )
}
