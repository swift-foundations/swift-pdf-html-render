// PDF.HTML.swift
// Namespace and helpers for HTML to PDF rendering

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import PDF_Standard
import Rendering
import W3C_CSS_Shared

extension PDF {
    /// Namespace for HTML to PDF rendering
    public enum HTML {}
}

// MARK: - Style Modifier Protocol


// MARK: - Main Entry Point

extension PDF.HTML {
    /// Render HTML content to PDF pages using static dispatch.
    ///
    /// This is the preferred entry point when the HTML type is known to conform
    /// to `PDF.HTML.View`, enabling full static dispatch throughout rendering.
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering
    ///   - html: The HTML view to render
    /// - Returns: Array of PDF pages
    public static func pages<H: PDF.HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> [PDF.Page] {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )
        
        // Apply configuration defaults
        pdfContext.style.font = configuration.defaultFont
        pdfContext.style.fontSize = configuration.defaultFontSize
        pdfContext.style.color = configuration.defaultColor
        // Resolve CSS line-height to concrete multiplier for PDF rendering
        pdfContext.style.lineHeight = Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))
        
        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)
        
        // Render HTML to PDF using static dispatch
        H._render(html(), context: &context)
        
        // Handle any remaining deferred content (e.g., sticky header at end of document)
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }
        
        // Flush any remaining inline runs
        context.pdf.flushInlineRuns()
        
        // Return all pages
        return context.pdf.pages
    }
}

extension PDF.HTML {
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
    /// - Returns: Array of PDF pages
    @_disfavoredOverload
    public static func pages<H: HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> [PDF.Page] {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )
        
        // Apply configuration defaults
        pdfContext.style.font = configuration.defaultFont
        pdfContext.style.fontSize = configuration.defaultFontSize
        pdfContext.style.color = configuration.defaultColor
        // Resolve CSS line-height to concrete multiplier for PDF rendering
        pdfContext.style.lineHeight = Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))
        
        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)
        
        // Render using dynamic dispatch
        renderHTMLView(html(), context: &context)
        
        // Handle any remaining deferred content (e.g., sticky header at end of document)
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }
        
        // Flush any remaining inline runs
        context.pdf.flushInlineRuns()
        
        // Return all pages
        return context.pdf.pages
    }
}

extension PDF.HTML {
    /// Dynamic dispatch helper for rendering any HTML.View.
    ///
    /// Checks if the view conforms to PDF.HTML.View and dispatches accordingly.
    /// Falls back to rendering the body recursively if no explicit conformance.
    ///
    /// Note: Swift's runtime type checking doesn't work with conditional conformances
    /// on variadic generics (`_Tuple`), so we handle _Tuple specially by iterating
    /// its content.
    public static func renderHTMLView(
        _ view: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        // Inner helper to open existentials
        func renderPDFView<V: PDF.HTML.View>(_ v: V) {
            V._render(v, context: &context)
        }

        // Try static dispatch if type conforms to PDF.HTML.View
        if let pdfView = view as? any PDF.HTML.View {
            renderPDFView(pdfView)
            return
        }

        // Handle _Tuple specially - Swift can't verify variadic conditional conformances at runtime
        // We use a marker protocol to enable dynamic rendering of tuple elements
        if let tuple = view as? any _TupleContent {
            tuple._renderEachElementDynamically(context: &context)
            return
        }

        // Fallback: render the body recursively
        func renderBody<V: HTML.View>(_ v: V) {
            renderHTMLView(v.body, context: &context)
        }
        renderBody(view)
    }
}

// MARK: - _Tuple Dynamic Dispatch Support

/// Internal protocol to enable dynamic dispatch for _Tuple without variadic constraints.
///
/// This works around Swift's limitation where runtime existential casts (`as? any Protocol`)
/// don't work correctly for conditional conformances on variadic generics.
package protocol _TupleContent {
    /// Render each element of the tuple using dynamic dispatch.
    func _renderEachElementDynamically(context: inout PDF.HTML.Context)
}

// MARK: - Block and Inline Helpers

extension PDF.HTML {
    /// Render content as a block element (flushes inline runs before and after).
    @inlinable
    public static func renderBlock<C: PDF.HTML.View>(
        _ content: C?,
        context: inout PDF.HTML.Context,
        beforeSpacing: Double = 0,
        afterSpacing: Double = 0
    ) {
        // Flush pending inline runs
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Add spacing before
        if beforeSpacing > 0 {
            context.pdf.advance(PDF.UserSpace.Y(PDF.UserSpace.Unit(beforeSpacing)))
        }

        // Render content
        if let content {
            C._render(content, context: &context)
        }

        // Flush inline runs from content
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Add spacing after
        if afterSpacing > 0 {
            context.pdf.advance(PDF.UserSpace.Y(PDF.UserSpace.Unit(afterSpacing)))
        }
    }

    /// Render content inline (no flush).
    @inlinable
    public static func renderInline<C: PDF.HTML.View>(
        _ content: C?,
        context: inout PDF.HTML.Context
    ) {
        if let content {
            C._render(content, context: &context)
        }
    }
}
