// PDF.HTML.swift
// Namespace and helpers for HTML to PDF rendering

import HTML_Renderable
import PDF_Rendering
import PDF_Standard
import Renderable
import W3C_CSS_Shared

extension PDF {
    /// Namespace for HTML to PDF rendering
    public enum HTML {}
}

// MARK: - Style Modifier Protocol

extension PDF.HTML {
    /// Protocol for CSS properties that can modify PDF rendering context.
    ///
    /// CSS property types conform to this protocol to define how they affect
    /// PDF rendering. This enables the same `.inlineStyle(...)` API used for
    /// HTML to also affect PDF output.
    ///
    /// Example conformance:
    /// ```swift
    /// extension FontWeight: PDF.HTML.StyleModifier {
    ///     public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
    ///         if self == .bold { context.font = context.font.bold }
    ///     }
    /// }
    /// ```
    public protocol StyleModifier {
        /// Apply this style to the PDF rendering context.
        func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration)
    }
}

// MARK: - Tag Renderer Protocol (Internal)

extension PDF.HTML {
    /// Internal protocol for tags that provide intrinsic PDF styling.
    ///
    /// Tags conform to this to define intrinsic style changes (font, size, color)
    /// that mirror browser user-agent stylesheets. For example, `<h1>` is bold
    /// and 2em size, `<em>` is italic.
    ///
    /// The save/restore of style state is handled by HTML.Element.
    internal protocol TagRenderer {
        /// Apply tag-specific styling to the context.
        static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration)
    }
}

// MARK: - Main Entry Point

extension PDF.HTML {
    /// Render HTML content into PDF render operations.
    ///
    /// - Parameters:
    ///   - html: The HTML view to render
    ///   - configuration: Configuration for the rendering
    /// - Returns: A tuple of (operations per page, annotations per page)
    public static func pages<H: HTML_Renderable.HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H,
    ) -> (pages: [[PDF.Render.Operation]], annotations: [[PDF.Annotation]]) {
        var context = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )

        // Apply configuration defaults
        context.font = configuration.defaultFont
        context.fontSize = configuration.defaultFontSize
        context.color = configuration.defaultColor
        context.lineHeight = configuration.lineHeight

        // Buffer for collecting operations
        var buffer: [PDF.Render.Operation] = []

        // Render HTML to PDF
        PDF.HTML.render(html(), into: &buffer, context: &context, configuration: configuration)

        // Flush any remaining inline runs
        _ = context.flushInlineRuns()

        // Add buffer contents to current page operations
        context.add(buffer)

        // Return all pages
        return (context.getAllPages(), context.getAllAnnotations())
    }
}

// MARK: - Block and Inline Helpers

extension PDF.HTML {
    /// Render content as a block element (flushes inline runs before and after).
    public static func renderBlock<
        Buffer: RangeReplaceableCollection,
        C: HTML_Renderable.HTML.View
    >(
        _ content: C?,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration,
        beforeSpacing: Double = 0,
        afterSpacing: Double = 0
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush pending inline runs
        _ = context.flushInlineRuns()

        // Add spacing before
        if beforeSpacing > 0 {
            context.advance(PDF.UserSpace.Y(PDF.UserSpace.Unit(beforeSpacing)))
        }

        // Render content
        if let content {
            render(content, into: &buffer, context: &context, configuration: configuration)
        }

        // Flush inline runs from content
        _ = context.flushInlineRuns()

        // Add spacing after
        if afterSpacing > 0 {
            context.advance(PDF.UserSpace.Y(PDF.UserSpace.Unit(afterSpacing)))
        }
    }

    /// Render content inline (no flush).
    public static func renderInline<
        Buffer: RangeReplaceableCollection,
        C: HTML_Renderable.HTML.View
    >(
        _ content: C?,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        if let content {
            render(content, into: &buffer, context: &context, configuration: configuration)
        }
    }
}
