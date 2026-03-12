// PDF.HTML+BlockInlineHelpers.swift
// Block and inline rendering helpers for static and dynamic dispatch paths

import HTML_Renderable
import PDF_Rendering

// MARK: - Block and Inline Helpers

extension PDF.HTML {
    /// Render content as a block element (flushes inline runs before and after).
    @inlinable
    public static func renderBlock<C: PDF.HTML.View>(
        _ content: C?,
        context: inout PDF.HTML.Context,
        beforeSpacing: PDF.UserSpace.Height = .init(0),
        afterSpacing: PDF.UserSpace.Height = .init(0)
    ) {
        // Flush pending inline runs
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Add spacing before
        if beforeSpacing > .init(0) {
            context.pdf.advance(beforeSpacing)
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
        if afterSpacing > .init(0) {
            context.pdf.advance(afterSpacing)
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

    // MARK: - Dynamic Dispatch Helpers

    /// Dynamic dispatch version of renderBlock.
    ///
    /// Use this when the content type is only known to conform to `HTML.View`,
    /// not `PDF.HTML.View`. This enables rendering of content that uses custom
    /// view types without explicit PDF conformance.
    public static func renderBlockDynamic(
        _ content: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        // Flush pending inline runs
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Render content using dynamic dispatch
        renderHTMLView(content, context: &context)

        // Flush inline runs from content
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }
    }

    /// Dynamic dispatch version of renderInline.
    ///
    /// Use this when the content type is only known to conform to `HTML.View`,
    /// not `PDF.HTML.View`. This enables rendering of content that uses custom
    /// view types without explicit PDF conformance.
    public static func renderInlineDynamic(
        _ content: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        renderHTMLView(content, context: &context)
    }
}
