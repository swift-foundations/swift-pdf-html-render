// HTML.InlineStyle+PDF.HTML.View.swift
// PDF rendering support for HTML.InlineStyle CSS wrapper

import HTML_Renderable
import PDF_Rendering
import W3C_CSS_Shared

/// PDF rendering for HTML.InlineStyle elements.
///
/// When rendering HTML to PDF, inline styles that conform to `PDF.HTML.StyleModifier`
/// are applied to the PDF context. This enables the same `.inlineStyle(FontWeight.bold)`
/// API used for HTML to also affect PDF output.
///
/// Example:
/// ```swift
/// p { "Bold text" }
///     .inlineStyle(FontWeight.bold)  // Works for both HTML and PDF!
/// ```
extension HTML.InlineStyle: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Save current style state
        let savedFont = context.pdf.font
        let savedFontSize = context.pdf.fontSize
        let savedColor = context.pdf.color

        defer {
            // Restore style state after rendering content
            context.pdf.font = savedFont
            context.pdf.fontSize = savedFontSize
            context.pdf.color = savedColor
        }

        // Check if this is a page-break-after: avoid style
        var shouldAvoidPageBreakAfter = false
        if let style = view.style {
            // Check for PDF context modifier
            if let modifier = style.property as? any PDF.HTML.StyleModifier {
                modifier.apply(to: &context.pdf, configuration: context.configuration)
            }
            // Check for HTML context modifier (for page-break-after, etc.)
            if let htmlModifier = style.property as? any PDF.HTML.HTMLContextStyleModifier {
                htmlModifier.apply(to: &context)
            }
            // Check if this is page-break-after: avoid
            if context.avoidPageBreakAfter {
                shouldAvoidPageBreakAfter = true
                context.avoidPageBreakAfter = false  // Reset the flag
            }
        }

        if shouldAvoidPageBreakAfter {
            // Capture context snapshot for restoration during deferred render
            let snapshot = PDF.HTML.Context.PDFContextSnapshot(from: context.pdf)
            let configuration = context.configuration

            // Measure the content height without rendering (measurement mode suppresses operations)
            // We need to create a fresh HTML context inside the measure closure to avoid access conflicts
            // Copy pending margin state to get accurate height including collapsed margins
            let pendingBottomMargin = context.pendingBottomMargin
            let measuredHeight = context.pdf.measure { measureContext in
                var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                snapshot.restore(to: &tempHTMLContext.pdf)
                var tempBuffer: [PDF.Render.Operation] = []
                Content._render(view.content, into: &tempBuffer, context: &tempHTMLContext)
                _ = tempHTMLContext.pdf.flushInlineRuns()
                // Write back the Y position to measureContext so the measure function can calculate height
                measureContext.y = tempHTMLContext.pdf.y
            }

            // Check if there's already deferred content (consecutive sticky headers)
            if let existingDeferred = context.deferredKeepWithNextRender {
                // Chain: combine heights and render in sequence
                let combinedHeight = PDF.UserSpace.Height(
                    existingDeferred.measuredHeight.value + measuredHeight.value
                )
                context.deferredKeepWithNextRender = PDF.HTML.Context.DeferredRender(
                    render: { buffer, ctx in
                        // Render existing deferred content first
                        existingDeferred.render(&buffer, &ctx)
                        // Then render this content
                        snapshot.restore(to: &ctx.pdf)
                        Content._render(view.content, into: &buffer, context: &ctx)
                        _ = ctx.pdf.flushInlineRuns()
                    },
                    measuredHeight: combinedHeight
                )
            } else {
                // Store deferred render closure (NOT executed yet)
                context.deferredKeepWithNextRender = PDF.HTML.Context.DeferredRender(
                    render: { buffer, ctx in
                        snapshot.restore(to: &ctx.pdf)
                        Content._render(view.content, into: &buffer, context: &ctx)
                        _ = ctx.pdf.flushInlineRuns()
                    },
                    measuredHeight: measuredHeight
                )
            }
        } else {
            // Normal rendering
            Content._render(view.content, into: &buffer, context: &context)
        }
    }
}
