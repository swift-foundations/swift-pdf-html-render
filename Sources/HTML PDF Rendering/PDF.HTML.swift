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

    /// Protocol for list container tags (ul, ol) that manage list context.
    internal protocol ListContainer {
        /// Get the list type for this container.
        static func listType() -> PDF.Context.ListType
    }

    /// Protocol for list item tags that render markers.
    internal protocol ListItemRenderer {
        /// Render the list marker and return the marker width.
        static func renderMarker(
            context: inout PDF.Context,
            configuration: PDF.HTML.Configuration
        ) -> PDF.UserSpace.Width
    }

    // MARK: - Table Protocols

    /// Protocol for table container tags (table)
    internal protocol TableContainer {}

    /// Protocol for table row tags (tr)
    internal protocol TableRowContainer {}

    /// Protocol for table cell tags (td, th)
    internal protocol TableCellContainer {}

    /// Protocol for table section tags (thead, tbody, tfoot) - pass through
    internal protocol TableSectionContainer {}

    // MARK: - Void Element Protocol

    /// Protocol for void element tags (br, hr, img, etc.) that have no content.
    ///
    /// Unlike `TagRenderer` which modifies styling for content, void elements
    /// perform their action directly without rendering any child content.
    internal protocol VoidElementRenderer {
        /// Render this void element's effect (e.g., line break, horizontal rule).
        static func render<Buffer: RangeReplaceableCollection>(
            into buffer: inout Buffer,
            context: inout PDF.HTML.Context
        ) where Buffer.Element == PDF.Render.Operation
    }
}

// MARK: - Main Entry Point

extension PDF.HTML {
    /// Render HTML content into PDF render operations using static dispatch.
    ///
    /// This is the preferred entry point when the HTML type is known to conform
    /// to `PDF.HTML.View`, enabling full static dispatch throughout rendering.
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering
    ///   - html: The HTML view to render
    /// - Returns: A tuple of (operations per page, annotations per page)
    public static func pages<H: PDF.HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H,
    ) -> (pages: [[PDF.Render.Operation]], annotations: [[PDF.Annotation]]) {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )

        // Apply configuration defaults
        pdfContext.font = configuration.defaultFont
        pdfContext.fontSize = configuration.defaultFontSize
        pdfContext.color = configuration.defaultColor
        pdfContext.lineHeight = configuration.lineHeight

        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)

        // Buffer for collecting operations
        var buffer: [PDF.Render.Operation] = []

        // Render HTML to PDF using static dispatch
        H._render(html(), into: &buffer, context: &context)

        // Flush any remaining inline runs
        _ = context.pdf.flushInlineRuns()

        // Add buffer contents to current page operations
        context.pdf.add(buffer)

        // Return all pages
        return (context.pdf.getAllPages(), context.pdf.getAllAnnotations())
    }

    /// Render any HTML.View to PDF using dynamic dispatch.
    ///
    /// This overload accepts any `HTML.View` and uses runtime checks to dispatch
    /// to the appropriate `PDF.HTML.View._render` implementation. Use this when
    /// working with custom views that haven't explicitly declared `PDF.HTML.View`
    /// conformance.
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering
    ///   - html: The HTML view to render
    /// - Returns: A tuple of (operations per page, annotations per page)
    @_disfavoredOverload
    public static func pages<H: HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H,
    ) -> (pages: [[PDF.Render.Operation]], annotations: [[PDF.Annotation]]) {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )

        // Apply configuration defaults
        pdfContext.font = configuration.defaultFont
        pdfContext.fontSize = configuration.defaultFontSize
        pdfContext.color = configuration.defaultColor
        pdfContext.lineHeight = configuration.lineHeight

        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)

        // Buffer for collecting operations
        var buffer: [PDF.Render.Operation] = []

        // Render using dynamic dispatch
        renderHTMLView(html(), into: &buffer, context: &context)

        // Flush any remaining inline runs
        _ = context.pdf.flushInlineRuns()

        // Add buffer contents to current page operations
        context.pdf.add(buffer)

        // Return all pages
        return (context.pdf.getAllPages(), context.pdf.getAllAnnotations())
    }

    /// Dynamic dispatch helper for rendering any HTML.View.
    ///
    /// Checks if the view conforms to PDF.HTML.View and dispatches accordingly.
    /// Falls back to rendering the body recursively if no explicit conformance.
    ///
    /// Note: Swift's runtime type checking doesn't work with conditional conformances
    /// on variadic generics (`_Tuple`), so we handle _Tuple specially by iterating
    /// its content.
    public static func renderHTMLView<Buffer: RangeReplaceableCollection>(
        _ view: some HTML.View,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Inner helper to open existentials
        func renderPDFView<V: PDF.HTML.View>(_ v: V) {
            V._render(v, into: &buffer, context: &context)
        }

        // Try static dispatch if type conforms to PDF.HTML.View
        if let pdfView = view as? any PDF.HTML.View {
            renderPDFView(pdfView)
            return
        }

        // Handle _Tuple specially - Swift can't verify variadic conditional conformances at runtime
        // We use a marker protocol to enable dynamic rendering of tuple elements
        if let tuple = view as? any _TupleContent {
            tuple._renderEachElementDynamically(into: &buffer, context: &context)
            return
        }

        // Fallback: render the body recursively
        func renderBody<V: HTML.View>(_ v: V) {
            renderHTMLView(v.body, into: &buffer, context: &context)
        }
        renderBody(view)
    }
}

// MARK: - _Tuple Dynamic Dispatch Support

/// Internal protocol to enable dynamic dispatch for _Tuple without variadic constraints.
///
/// This works around Swift's limitation where runtime existential casts (`as? any Protocol`)
/// don't work correctly for conditional conformances on variadic generics.
public protocol _TupleContent {
    /// Render each element of the tuple using dynamic dispatch.
    func _renderEachElementDynamically<Buffer: RangeReplaceableCollection>(
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation
}

// MARK: - Block and Inline Helpers

extension PDF.HTML {
    /// Render content as a block element (flushes inline runs before and after).
    @inlinable
    public static func renderBlock<
        Buffer: RangeReplaceableCollection,
        C: PDF.HTML.View
    >(
        _ content: C?,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context,
        beforeSpacing: Double = 0,
        afterSpacing: Double = 0
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush pending inline runs
        _ = context.pdf.flushInlineRuns()

        // Add spacing before
        if beforeSpacing > 0 {
            context.pdf.advance(PDF.UserSpace.Y(PDF.UserSpace.Unit(beforeSpacing)))
        }

        // Render content
        if let content {
            C._render(content, into: &buffer, context: &context)
        }

        // Flush inline runs from content
        _ = context.pdf.flushInlineRuns()

        // Add spacing after
        if afterSpacing > 0 {
            context.pdf.advance(PDF.UserSpace.Y(PDF.UserSpace.Unit(afterSpacing)))
        }
    }

    /// Render content inline (no flush).
    @inlinable
    public static func renderInline<
        Buffer: RangeReplaceableCollection,
        C: PDF.HTML.View
    >(
        _ content: C?,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        if let content {
            C._render(content, into: &buffer, context: &context)
        }
    }
}
