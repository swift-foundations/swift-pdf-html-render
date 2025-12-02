// PDFConvertible.swift

import HTML_Rendering
import PDF_Rendering

/// Protocol for HTML types that can be directly converted to PDF views.
///
/// This protocol enables direct tree transformation from HTML.View to PDF.View
/// without intermediate string serialization and parsing.
///
/// Example:
/// ```swift
/// let html: some HTML.View = div { strong { "Hello" } }
/// let pdfView = html.toPDFView(configuration: .default, style: .empty)
/// ```
public protocol PDFConvertible {
    /// Convert this HTML view to a PDF view.
    ///
    /// - Parameters:
    ///   - configuration: PDF conversion settings (paper size, fonts, etc.)
    ///   - style: Current computed style from parent elements
    /// - Returns: A PDF.View representing this HTML content
    func toPDFView(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View
}

// MARK: - HTML.Element Conformance

extension HTML.Element: PDFConvertible {
    public func toPDFView(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        // Dispatch based on tag name
        convertTagToPDF(
            tag: tag,
            content: content,
            configuration: configuration,
            style: style
        )
    }
}

// MARK: - HTML.Text Conformance

extension HTML.Text: PDFConvertible {
    public func toPDFView(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        PDF.Text(
            text,
            font: PDF.Font(style, base: configuration.defaultFont),
            fontSize: style.fontSize ?? configuration.defaultFontSize,
            color: style.color ?? configuration.defaultColor
        )
    }
}

// MARK: - HTML._Attributes Conformance

extension HTML._Attributes: PDFConvertible where Content: PDFConvertible {
    public func toPDFView(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        // Convert OrderedDictionary to Dictionary for style extraction
        var dict: [String: String] = [:]
        for (key, value) in attributes {
            dict[key] = value
        }

        // Extract style from attributes and merge with current style
        let attributeStyle = HTML.ElementMapping.styleFromAttributes(dict)
        let mergedStyle = style.merging(attributeStyle)

        // Convert the wrapped content
        return content.toPDFView(configuration: configuration, style: mergedStyle)
    }
}

// MARK: - String Conformance

extension String: PDFConvertible {
    public func toPDFView(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        PDF.Text(
            self,
            font: PDF.Font(style, base: configuration.defaultFont),
            fontSize: style.fontSize ?? configuration.defaultFontSize,
            color: style.color ?? configuration.defaultColor
        )
    }
}

// MARK: - Optional Conformance

extension Optional: PDFConvertible where Wrapped: PDFConvertible {
    public func toPDFView(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        switch self {
        case .some(let value):
            return value.toPDFView(configuration: configuration, style: style)
        case .none:
            return PDF.Content()
        }
    }
}

// MARK: - Never Conformance

extension Never: PDFConvertible {
    public func toPDFView(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        fatalError("Never cannot be converted to PDF")
    }
}

// MARK: - Tag Conversion Helper

/// Convert an HTML tag to PDF primitives based on tag name.
private func convertTagToPDF<Content: HTML.View>(
    tag: String,
    content: Content?,
    configuration: HTML.Configuration,
    style: HTML.ComputedStyle
) -> any PDF.View {
    // Try to convert content if it's PDFConvertible
    func convertContent(with childStyle: HTML.ComputedStyle) -> any PDF.View {
        if let convertible = content as? (any PDFConvertible) {
            return convertible.toPDFView(configuration: configuration, style: childStyle)
        } else if let content = content {
            // Fallback to string-based conversion for non-PDFConvertible content
            return HTML.ElementMapping.convert(content, configuration: configuration, style: childStyle)
        } else {
            return PDF.Content()
        }
    }

    switch tag.lowercased() {
    // Headings
    case "h1":
        let headingStyle = style.merging(HTML.ComputedStyle(
            fontSize: configuration.headingSize(level: 1),
            fontWeight: .bold
        ))
        let childView = convertContent(with: headingStyle)
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(headingStyle.fontSize ?? configuration.defaultFontSize)
        ])

    case "h2":
        let headingStyle = style.merging(HTML.ComputedStyle(
            fontSize: configuration.headingSize(level: 2),
            fontWeight: .bold
        ))
        let childView = convertContent(with: headingStyle)
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(headingStyle.fontSize ?? configuration.defaultFontSize)
        ])

    case "h3":
        let headingStyle = style.merging(HTML.ComputedStyle(
            fontSize: configuration.headingSize(level: 3),
            fontWeight: .bold
        ))
        let childView = convertContent(with: headingStyle)
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(headingStyle.fontSize ?? configuration.defaultFontSize)
        ])

    case "h4":
        let headingStyle = style.merging(HTML.ComputedStyle(
            fontSize: configuration.headingSize(level: 4),
            fontWeight: .bold
        ))
        let childView = convertContent(with: headingStyle)
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(headingStyle.fontSize ?? configuration.defaultFontSize)
        ])

    case "h5":
        let headingStyle = style.merging(HTML.ComputedStyle(
            fontSize: configuration.headingSize(level: 5),
            fontWeight: .bold
        ))
        let childView = convertContent(with: headingStyle)
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(headingStyle.fontSize ?? configuration.defaultFontSize)
        ])

    case "h6":
        let headingStyle = style.merging(HTML.ComputedStyle(
            fontSize: configuration.headingSize(level: 6),
            fontWeight: .bold
        ))
        let childView = convertContent(with: headingStyle)
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(headingStyle.fontSize ?? configuration.defaultFontSize)
        ])

    // Paragraph
    case "p":
        let childView = convertContent(with: style)
        let spacing = (style.fontSize ?? configuration.defaultFontSize) * 0.5
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(spacing)
        ])

    // Inline formatting
    case "strong", "b":
        let boldStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
        return convertContent(with: boldStyle)

    case "em", "i":
        let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
        return convertContent(with: italicStyle)

    case "code":
        let codeStyle = style.merging(HTML.ComputedStyle(
            fontSize: (style.fontSize ?? configuration.defaultFontSize) * 0.9
        ))
        return convertContent(with: codeStyle)

    case "pre":
        let preStyle = style.merging(HTML.ComputedStyle(
            fontSize: (style.fontSize ?? configuration.defaultFontSize) * 0.9
        ))
        let childView = convertContent(with: preStyle)
        let spacing = (style.fontSize ?? configuration.defaultFontSize) * 0.5
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(spacing)
        ])

    // Block containers (pass through)
    case "div", "section", "article", "header", "footer", "main", "aside", "nav", "span":
        return convertContent(with: style)

    // Line break
    case "br":
        return PDF.Spacer(style.fontSize ?? configuration.defaultFontSize)

    // Horizontal rule
    case "hr":
        return PDF.VStack(spacing: 0, children: [
            PDF.Spacer((style.fontSize ?? configuration.defaultFontSize) * 0.5),
            PDF.Divider(color: style.color ?? .gray50, thickness: 1),
            PDF.Spacer((style.fontSize ?? configuration.defaultFontSize) * 0.5)
        ])

    // Blockquote
    case "blockquote":
        let quoteStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
        let childView = convertContent(with: quoteStyle)
        let spacing = (style.fontSize ?? configuration.defaultFontSize) * 0.5
        return PDF.VStack(spacing: 0, children: [
            PDF.Spacer(spacing),
            childView,
            PDF.Spacer(spacing)
        ])

    // Lists - these need special handling
    case "ul", "ol", "li":
        // For lists, fall back to string parsing since they require
        // special structure extraction
        if let content = content {
            return HTML.ElementMapping.convert(content, configuration: configuration, style: style)
        }
        return PDF.Content()

    // Default: treat as container
    default:
        return convertContent(with: style)
    }
}
