// HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import CSS

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
        // Look up renderer in registry
        if let rendererType = PDFElementRendererRegistry.shared.renderer(for: tag) {
            // Wrap content as HTMLToPDFConvertible
            let children: [any HTMLToPDFConvertible]
            if let content = content {
                children = [HTMLViewWrapper(content)]
            } else {
                children = []
            }

            // Use registry-based renderer
            do {
                try rendererType.render(
                    tag: tag,
                    attributes: [:],  // HTML.Element doesn't expose attributes directly
                    children: children,
                    style: style,
                    context: &context,
                    configuration: configuration
                )
            } catch {
                // Silently handle render errors for now
            }
            return PDF.Content()
        }

        // Fallback: render content directly with convertToPDF
        if let content = content {
            return convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )
        }
        return PDF.Content()
    }
}

// MARK: - HTMLViewWrapper

/// Internal wrapper to bridge any HTML.View to HTMLToPDFConvertible.
///
/// This enables the registry-based renderers to work with generic HTML.View content.
private struct HTMLViewWrapper<Content: HTML.View>: HTMLToPDFConvertible {
    let content: Content

    init(_ content: Content) {
        self.content = content
    }

    var body: Never {
        fatalError("HTMLViewWrapper should not access body")
    }

    func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        convertToPDF(
            content,
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

extension Swift.Optional: HTMLToPDFConvertible where Wrapped: HTML.View {
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

// MARK: - HTML.AnyView Conformance

extension HTML.AnyView: HTMLToPDFConvertible {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // HTML.AnyView stores the wrapped view in `base` as `any HTML.View`
        // We render it through convertToPDF which handles the type-erased content
        return convertToPDF(
            base,
            configuration: configuration,
            style: style,
            context: &context
        )
    }
}

// MARK: - CSS<Base> Conformance

extension CSS: HTMLToPDFConvertible where Base: HTML.View {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // CSS<Base> is a wrapper that provides fluent CSS property access
        // The actual styles are applied to the base via .inlineStyle() calls
        // We simply render the wrapped base content
        return convertToPDF(
            base,
            configuration: configuration,
            style: style,
            context: &context
        )
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
