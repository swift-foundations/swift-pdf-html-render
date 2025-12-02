// HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering

/// Protocol for HTML types that can be rendered directly to PDF.
///
/// This protocol enables 100% type-safe conversion from HTML.View types
/// to PDF content without intermediate string serialization.
///
/// Conforming types implement `renderToPDF` which returns `PDF.Content`
/// directly, avoiding type erasure.
public protocol HTMLToPDFConvertible: HTML.View {
    /// Render this HTML view to PDF content operations.
    ///
    /// - Parameters:
    ///   - configuration: PDF conversion settings (paper size, fonts, etc.)
    ///   - style: Current computed style inherited from parent elements
    ///   - context: Mutable PDF context tracking position and state
    /// - Returns: PDF content operations for this view
    func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content
}

// MARK: - HTML.Text Conformance

extension HTML.Text: HTMLToPDFConvertible {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Append as text run instead of rendering directly.
        // Block elements will flush accumulated runs with proper line wrapping.
        context.appendInlineRun(PDF.TextRun(
            text: text,
            font: PDF.Font(style, base: configuration.defaultFont),
            fontSize: style.fontSize ?? configuration.defaultFontSize,
            color: style.color ?? configuration.defaultColor
        ))
        return PDF.Content()
    }
}

// MARK: - String Conformance

extension String: HTMLToPDFConvertible {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Append as text run instead of rendering directly.
        // Block elements will flush accumulated runs with proper line wrapping.
        context.appendInlineRun(PDF.TextRun(
            text: self,
            font: PDF.Font(style, base: configuration.defaultFont),
            fontSize: style.fontSize ?? configuration.defaultFontSize,
            color: style.color ?? configuration.defaultColor
        ))
        return PDF.Content()
    }
}

// MARK: - HTML.Element Conformance

extension HTML.Element: HTMLToPDFConvertible {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        PDF.ElementRenderer.render(
            tag: tag,
            content: content,
            configuration: configuration,
            style: style,
            context: &context
        )
    }
}

// MARK: - HTML._Attributes Conformance

extension HTML._Attributes: HTMLToPDFConvertible {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Convert OrderedDictionary to Dictionary for style extraction
        var dict: [String: String] = [:]
        for (key, value) in attributes {
            dict[key] = value
        }

        // Extract style from attributes and merge with current style
        let attributeStyle = HTML.ElementMapping.styleFromAttributes(dict)
        let mergedStyle = style.merging(attributeStyle)

        // Render the wrapped content with merged style using internal conversion
        return convertToPDF(
            content,
            configuration: configuration,
            style: mergedStyle,
            context: &context
        )
    }
}

// MARK: - Optional Conformance

extension Optional: HTMLToPDFConvertible where Wrapped: HTML.View {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        switch self {
        case .some(let value):
            return convertToPDF(
                value,
                configuration: configuration,
                style: style,
                context: &context
            )
        case .none:
            return PDF.Content()
        }
    }
}

// MARK: - Never Conformance

extension Never: HTMLToPDFConvertible {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        fatalError("Never cannot be rendered to PDF")
    }
}

// MARK: - HTML.InlineStyle Conformance

extension HTML.InlineStyle: HTMLToPDFConvertible {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Extract CSS styles from this InlineStyle wrapper
        let cssStyles = extractStyles()

        // Convert CSS property/value pairs to HTML.ComputedStyle
        let cssStyle = HTML.ElementMapping.styleFromCSSProperties(cssStyles)

        // Merge with inherited style
        let mergedStyle = style.merging(cssStyle)

        // Extract and render the wrapped content
        let content = extractContent()
        return convertToPDF(
            content,
            configuration: configuration,
            style: mergedStyle,
            context: &context
        )
    }
}
