// HTML.swift

public import PDF_Rendering
public import HTML_Renderable

// MARK: - PDF.Document from HTML

extension PDF.Document {
    /// Create a PDF document from an HTML view using a builder closure.
    ///
    /// This initializer converts HTML views to PDF. The HTML content
    /// is rendered to PDF using type-safe conversion. Multi-page documents
    /// are automatically created when content exceeds page boundaries.
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
        let pages = renderHTMLToPages(html, configuration: configuration)
        
        // Build info if any metadata provided
        let info: PDF.Document.Info? = (title != nil || author != nil || subject != nil || keywords != nil)
        ? PDF.Document.Info(title: title, author: author, subject: subject, keywords: keywords)
        : nil
        
        self.init(pages: pages, info: info)
    }
    
    /// Create a PDF document from an existing HTML view.
    ///
    /// This initializer converts HTML views to PDF using type-safe conversion.
    /// Multi-page documents are automatically created when content exceeds
    /// page boundaries.
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
        let pages = renderHTMLToPages(html, configuration: configuration)
        
        // Build info if any metadata provided
        let info: PDF.Document.Info? = (title != nil || author != nil || subject != nil || keywords != nil)
        ? PDF.Document.Info(title: title, author: author, subject: subject, keywords: keywords)
        : nil
        
        self.init(pages: pages, info: info)
    }
}

// MARK: - PDF Rendering Helper

/// Render an HTML view to multiple PDF pages.
///
/// This function handles conversion of any HTML.View to PDF pages.
/// It supports all HTML DSL types through the HTMLToPDFConvertible protocol.
/// Content automatically flows across multiple pages when needed.
private func renderHTMLToPages<T: HTML.View>(
    _ html: T,
    configuration: HTML.Configuration
) -> [PDF.Page] {
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
    
    // Convert the HTML view to PDF content (operations are stored in context)
    let _ = PDF.Content(
        html,
        configuration: configuration,
        style: .empty,
        context: &context
    )
    
    // Flush any remaining inline runs at the end
    let _ = context.flushInlineRuns()
    
    // Get all pages from context
    let allPages = context.getAllPages()
    let allAnnotations = context.getAllAnnotations()

    // Create PDF.Page objects
    if allPages.isEmpty {
        // Return a single empty page if no content
        return [PDF.Page(
            paperSize: configuration.paperSize,
            margins: configuration.margins,
            content: PDF.Content()
        )]
    }

    return allPages.enumerated().map { (index, operations) in
        let annotations = index < allAnnotations.count ? allAnnotations[index] : []
        return PDF.Page(
            paperSize: configuration.paperSize,
            margins: configuration.margins,
            content: PDF.Content(operations: operations),
            annotations: annotations
        )
    }
}


// new one
extension PDF.Content {
    
    /// Internal conversion function that handles runtime type checking.
    ///
    /// This enables conversion of opaque `some HTML.View` types by checking
    /// conformance at runtime. For custom views that don't directly conform to
    /// HTMLToPDFConvertible, we recursively render their body property.
    internal init<T: HTML.View>(
        _ view: T,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) {
        // If the view directly conforms to HTMLToPDFConvertible, use static dispatch
        if let convertibleType = T.self as? any HTMLToPDFConvertible.Type {
            // Open existential and call static _renderToPDF
            func callRender<V: HTMLToPDFConvertible>(_ type: V.Type) -> PDF.Content {
                guard let typedView = view as? V else {
                    fatalError("Type mismatch in PDF.Content.init")
                }
                return V._renderToPDF(typedView, configuration: configuration, style: style, context: &context)
            }
            self = callRender(convertibleType)
            return
        }

        // For custom HTML.View types, recursively render their body
        // This mirrors how HTML rendering works - delegating to body
        self = PDF.Content(
            view.body,
            configuration: configuration,
            style: style,
            context: &context
        )
    }
}
