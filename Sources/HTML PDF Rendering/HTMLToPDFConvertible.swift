// HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import CSS

/// Protocol for HTML types that can be rendered directly to PDF.
///
/// This protocol enables 100% type-safe conversion from HTML.View types
/// to PDF content without intermediate string serialization.
///
/// Conforming types implement `_renderToPDF` which returns `PDF.Content`
/// directly, avoiding type erasure. The static method pattern mirrors
/// `Renderable._render` for compile-time type safety.
public protocol HTMLToPDFConvertible: HTML.View {
    /// Render this HTML view to PDF content operations.
    ///
    /// - Parameters:
    ///   - view: The view to render
    ///   - configuration: PDF conversion settings (paper size, fonts, etc.)
    ///   - style: Current computed style inherited from parent elements
    ///   - context: Mutable PDF context tracking position and state
    /// - Returns: PDF content operations for this view
    static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content
}

// MARK: - Default Implementation

extension HTMLToPDFConvertible where Content: HTMLToPDFConvertible {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        Content._renderToPDF(view.body, configuration: configuration, style: style, context: &context)
    }
}

// MARK: - Dynamic Dispatch Helper

extension HTML {
    /// Renders an HTML view to PDF using dynamic dispatch.
    /// Use this when you have `any HTMLToPDFConvertible` and need to call `_renderToPDF`.
    @inlinable
    public static func renderToPDF(
        _ view: some HTMLToPDFConvertible,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        func callRender<V: HTMLToPDFConvertible>(_ v: V) -> PDF.Content {
            V._renderToPDF(v, configuration: configuration, style: style, context: &context)
        }
        return callRender(view)
    }
}

// MARK: - HTML.Text Conformance

extension HTML.Text: HTMLToPDFConvertible {
    public typealias Content = Never

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Append as text run instead of rendering directly.
        // Block elements will flush accumulated runs with proper line wrapping.
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        context.appendInlineRun(PDF.TextRun(
            text: view.text,
            font: PDF.Font(style, base: configuration.defaultFont),
            fontSize: fontSize,
            color: style.color ?? configuration.defaultColor,
            textDecoration: style.textDecoration?.toPDFDecoration ?? .none,
            backgroundColor: style.backgroundColor,
            verticalOffset: style.verticalAlign?.toOffset(fontSize: fontSize) ?? 0,
            linkURL: style.linkURL
        ))
        return PDF.Content()
    }
}

// MARK: - Text Decoration Conversion

extension HTML.ComputedStyle.TextDecoration {
    /// Convert HTML text decoration to PDF text decoration
    var toPDFDecoration: PDF.TextDecoration {
        switch self {
        case .none: return .none
        case .underline: return .underline
        case .lineThrough: return .lineThrough
        case .overline: return .none  // Not supported in PDF.TextDecoration
        }
    }
}

// MARK: - Vertical Align Conversion

extension HTML.ComputedStyle.VerticalAlign {
    /// Convert vertical alignment to a Y offset in points
    /// Positive = up, Negative = down
    func toOffset(fontSize: Double) -> Double {
        switch self {
        case .super:
            return fontSize * 0.4  // Move up for superscript
        case .sub:
            return -fontSize * 0.2  // Move down for subscript
        case .baseline, .top, .middle, .bottom, .textTop, .textBottom:
            return 0  // No offset for other alignments
        }
    }
}

// MARK: - String Conformance

extension String: HTMLToPDFConvertible {
    public typealias Content = Never

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Append as text run instead of rendering directly.
        // Block elements will flush accumulated runs with proper line wrapping.
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        context.appendInlineRun(PDF.TextRun(
            text: view,
            font: PDF.Font(style, base: configuration.defaultFont),
            fontSize: fontSize,
            color: style.color ?? configuration.defaultColor,
            textDecoration: style.textDecoration?.toPDFDecoration ?? .none,
            backgroundColor: style.backgroundColor,
            verticalOffset: style.verticalAlign?.toOffset(fontSize: fontSize) ?? 0
        ))
        return PDF.Content()
    }
}

// MARK: - HTML.Element Conformance

extension HTML.Element: HTMLToPDFConvertible {
    public typealias Content = Never

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Check if the Tag type conforms to PDF.Stylable for type-safe styling
        let mergedStyle: HTML.ComputedStyle
        if let stylableType = Tag.self as? any PDF.Stylable.Type {
            let pdfStyle = stylableType.pdfStyle
            mergedStyle = style.merging(pdfStyle.toComputedStyle(configuration: configuration))
        } else {
            mergedStyle = style
        }

        // Wrap content as HTMLToPDFConvertible
        let children: [any HTMLToPDFConvertible]
        if let content = view.content {
            children = [HTMLViewWrapper(content)]
        } else {
            children = []
        }

        // Type-safe dispatch: call _renderToPDF directly on the Tag type
        do {
            try Tag._renderToPDF(
                children: children,
                style: mergedStyle,
                context: &context,
                configuration: configuration
            )
        } catch {
            // Silently handle render errors for now
        }
        return PDF.Content()
    }
}

// MARK: - HTMLViewWrapper

/// Internal wrapper to bridge any HTML.View to HTMLToPDFConvertible.
///
/// This enables the registry-based renderers to work with generic HTML.View content.
private struct HTMLViewWrapper<Wrapped: HTML.View>: HTMLToPDFConvertible {
    typealias Content = Never

    let wrapped: Wrapped

    init(_ wrapped: Wrapped) {
        self.wrapped = wrapped
    }

    var body: Never {
        fatalError("HTMLViewWrapper should not access body")
    }

    static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        PDF.Content(
            view.wrapped,
            configuration: configuration,
            style: style,
            context: &context
        )
    }
}

// MARK: - HTML._Attributes Conformance

extension HTML._Attributes: HTMLToPDFConvertible where Content: HTML.View {
    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Convert OrderedDictionary to Dictionary for style extraction
        var dict: [String: String] = [:]
        for (key, value) in view.attributes {
            dict[key] = value
        }

        // Extract style from attributes and merge with current style
        let attributeStyle = HTML.ElementMapping.styleFromAttributes(dict)
        let mergedStyle = style.merging(attributeStyle)

        // Render the wrapped content with merged style
        return PDF.Content(
            view.content,
            configuration: configuration,
            style: mergedStyle,
            context: &context
        )
    }
}

// MARK: - Optional Conformance

extension Swift.Optional: HTMLToPDFConvertible where Wrapped: HTML.View {
    // Note: Content = Never is already defined in Optional's Renderable conformance

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        switch view {
        case .some(let value):
            return PDF.Content(
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
    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        fatalError("Never cannot be rendered to PDF")
    }
}

// MARK: - HTML.AnyView Conformance

extension HTML.AnyView: HTMLToPDFConvertible {
    // Note: Content = Never is already defined in HTML.AnyView's HTML.View conformance

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // HTML.AnyView stores the wrapped view in `base` as `any HTML.View`
        // We render it through PDF.Content.init which handles the type-erased content
        return PDF.Content(
            view.base,
            configuration: configuration,
            style: style,
            context: &context
        )
    }
}

// MARK: - HTML.Empty Conformance

extension HTML.Empty: HTMLToPDFConvertible {
    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Empty renders nothing - return empty content without accessing body
        return PDF.Content()
    }
}

// MARK: - CSS<Base> Conformance

extension CSS: HTMLToPDFConvertible where Base: HTML.View {
    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // CSS<Base> is a wrapper that provides fluent CSS property access
        // The actual styles are applied to the base via .inlineStyle() calls
        // We simply render the wrapped base content
        return PDF.Content(
            view.base,
            configuration: configuration,
            style: style,
            context: &context
        )
    }
}

// MARK: - HTML.InlineStyle Conformance

extension HTML.InlineStyle: HTMLToPDFConvertible {
    public typealias Content = Never

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        // Extract CSS style entries from this InlineStyle wrapper
        let cssStyles = view.extractStyleEntries()

        // Convert CSS property/value pairs to HTML.ComputedStyle
        let cssStyle = HTML.ElementMapping.styleFromCSSProperties(cssStyles)

        // Merge with inherited style
        let mergedStyle = style.merging(cssStyle)

        // Extract and render the wrapped content with merged style
        // Note: extractContent() returns `any HTML.View`, so we use PDF.Content.init
        let content = view.extractContent()
        return PDF.Content(
            content,
            configuration: configuration,
            style: mergedStyle,
            context: &context
        )
    }
}
