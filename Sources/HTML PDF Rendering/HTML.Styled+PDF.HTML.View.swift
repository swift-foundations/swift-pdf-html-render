// HTML.Styled+PDF.HTML.View.swift
// PDF rendering support for HTML.Styled CSS wrapper

import HTML_Renderable
import PDF_Rendering
import W3C_CSS_Shared

/// PDF rendering for HTML.Styled elements.
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
extension HTML.Styled: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Save current style state
        let savedStyle = context.pdf.style

        defer {
            // Restore style state after rendering content
            context.pdf.style = savedStyle
        }

        // Check if this is a page-break-after: avoid style
        var shouldAvoidPageBreakAfter = false
        if let property = view.property {
            // Check for PDF context modifier
            if let modifier = property as? any PDF.HTML.StyleModifier {
                modifier.apply(to: &context.pdf, configuration: context.configuration)
            }
            // Check for HTML context modifier (for page-break-after, etc.)
            if let htmlModifier = property as? any PDF.HTML.HTMLContextStyleModifier {
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
            let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
            let configuration = context.configuration

            // Measure the content height without rendering (measurement mode suppresses operations)
            // We need to create a fresh HTML context inside the measure closure to avoid access conflicts
            // Copy pending margin state to get accurate height including collapsed margins
            let pendingBottomMargin = context.pendingBottomMargin
            let measuredHeight = context.pdf.measure { measureContext in
                var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                snapshot.restore(to: &tempHTMLContext.pdf)
                Content._render(view.content, context: &tempHTMLContext)
                tempHTMLContext.pdf.flushInlineRuns()
                // Write back the Y position to measureContext so the measure function can calculate height
                measureContext.layoutBox.lly = tempHTMLContext.pdf.layoutBox.lly
            }
            // Check if there's already deferred content (consecutive sticky headers)
            if let existingDeferred = context.deferredKeepWithNextRender {
                // Chain: combine heights and render in sequence
                let combinedHeight = existingDeferred.measuredHeight + measuredHeight
                context.deferredKeepWithNextRender = PDF.HTML.Context.DeferredRender(
                    render: { ctx in
                        // Render existing deferred content first
                        existingDeferred.render(&ctx)
                        // Then render this content
                        snapshot.restore(to: &ctx.pdf)
                        Content._render(view.content, context: &ctx)
                        ctx.pdf.flushInlineRuns()
                    },
                    measuredHeight: combinedHeight
                )
            } else {
                // Store deferred render closure (NOT executed yet)
                context.deferredKeepWithNextRender = PDF.HTML.Context.DeferredRender(
                    render: { ctx in
                        snapshot.restore(to: &ctx.pdf)
                        Content._render(view.content, context: &ctx)
                        ctx.pdf.flushInlineRuns()
                    },
                    measuredHeight: measuredHeight
                )
            }
        } else {
            // Normal rendering
            Content._render(view.content, context: &context)
        }
    }
}
