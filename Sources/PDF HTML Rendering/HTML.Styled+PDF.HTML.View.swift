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

        // Save box model state
        let savedMarginTop = context.pdf.marginTop
        let savedMarginRight = context.pdf.marginRight
        let savedMarginBottom = context.pdf.marginBottom
        let savedMarginLeft = context.pdf.marginLeft
        let savedPaddingTop = context.pdf.paddingTop
        let savedPaddingRight = context.pdf.paddingRight
        let savedPaddingBottom = context.pdf.paddingBottom
        let savedPaddingLeft = context.pdf.paddingLeft
        let savedExplicitWidth = context.pdf.explicitWidth
        let savedExplicitHeight = context.pdf.explicitHeight
        let savedLayoutBox = context.pdf.layoutBox

        defer {
            // Restore style state after rendering content
            context.pdf.style = savedStyle

            // Restore box model state
            context.pdf.marginTop = savedMarginTop
            context.pdf.marginRight = savedMarginRight
            context.pdf.marginBottom = savedMarginBottom
            context.pdf.marginLeft = savedMarginLeft
            context.pdf.paddingTop = savedPaddingTop
            context.pdf.paddingRight = savedPaddingRight
            context.pdf.paddingBottom = savedPaddingBottom
            context.pdf.paddingLeft = savedPaddingLeft
            context.pdf.explicitWidth = savedExplicitWidth
            context.pdf.explicitHeight = savedExplicitHeight
            // Note: layoutBox is NOT restored - Y position should advance through content
            context.pdf.layoutBox.llx = savedLayoutBox.llx
            context.pdf.layoutBox.urx = savedLayoutBox.urx
        }

        // Check for break-related styles
        var shouldAvoidPageBreakAfter = false
        var shouldForcePageBreakAfter = false
        var shouldAvoidPageBreakInside = false

        if let property = view.property {
            // Check for PDF context modifier
            if let modifier = property as? any PDF.HTML.StyleModifier {
                modifier.apply(to: &context.pdf, configuration: context.configuration)
            }
            // Check for HTML context modifier (for page-break-after, break-inside, etc.)
            if let htmlModifier = property as? any PDF.HTML.HTMLContextStyleModifier {
                htmlModifier.apply(to: &context)
            }

            // Capture and reset break flags
            if context.avoidPageBreakAfter {
                shouldAvoidPageBreakAfter = true
                context.avoidPageBreakAfter = false
            }
            if context.forcePageBreakAfter {
                shouldForcePageBreakAfter = true
                context.forcePageBreakAfter = false
            }
            if context.avoidPageBreakInside {
                shouldAvoidPageBreakInside = true
                context.avoidPageBreakInside = false
            }
        }

        // Apply CSS Box Model
        // Margin: Apply vertical margins to Y position, horizontal margins to layout bounds
        if let marginTop = context.pdf.marginTop, marginTop._rawValue > 0 {
            context.pdf.advance(marginTop)
        }
        if let marginLeft = context.pdf.marginLeft {
            context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + marginLeft
        }
        if let marginRight = context.pdf.marginRight {
            context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - marginRight
        }

        // Padding: Inset the layout box for content
        if let paddingTop = context.pdf.paddingTop, paddingTop._rawValue > 0 {
            context.pdf.advance(paddingTop)
        }
        if let paddingLeft = context.pdf.paddingLeft {
            context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + paddingLeft
        }
        if let paddingRight = context.pdf.paddingRight {
            context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - paddingRight
        }

        // Explicit width/height constraints
        if let explicitWidth = context.pdf.explicitWidth {
            context.pdf.layoutBox.urx = context.pdf.layoutBox.llx + explicitWidth
        }

        // Handle break-inside: avoid
        // If element won't fit on current page but would fit on a fresh page, break first
        if shouldAvoidPageBreakInside {
            let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
            let configuration = context.configuration
            let pendingBottomMargin = context.pendingBottomMargin

            // Measure the element's total height
            let measuredHeight = context.pdf.measure { measureContext in
                var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                snapshot.restore(to: &tempHTMLContext.pdf)
                Content._render(view.content, context: &tempHTMLContext)
                tempHTMLContext.pdf.flushInlineRuns()
                measureContext.layoutBox.lly = tempHTMLContext.pdf.layoutBox.lly
            }

            // If it won't fit on current page but would fit on a fresh page, break before
            let pageContentHeight = context.configuration.content.height
            if context.pdf.wouldExceedPage(adding: measuredHeight) && measuredHeight <= pageContentHeight {
                context.pdf.startNewPage()
            }
        }

        // Handle break-after: avoid (sticky header behavior)
        if shouldAvoidPageBreakAfter {
            // Capture context snapshot for restoration during deferred render
            let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
            let configuration = context.configuration

            // Measure the content height without rendering (measurement mode suppresses operations)
            let pendingBottomMargin = context.pendingBottomMargin
            let measuredHeight = context.pdf.measure { measureContext in
                var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                snapshot.restore(to: &tempHTMLContext.pdf)
                Content._render(view.content, context: &tempHTMLContext)
                tempHTMLContext.pdf.flushInlineRuns()
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

            // Handle break-after: always/page (force page break)
            if shouldForcePageBreakAfter {
                context.pdf.flushInlineRuns()
                context.pdf.startNewPage()
            }
        }

        // Apply bottom padding and margin after content renders
        if let paddingBottom = context.pdf.paddingBottom, paddingBottom._rawValue > 0 {
            context.pdf.advance(paddingBottom)
        }
        if let marginBottom = context.pdf.marginBottom, marginBottom._rawValue > 0 {
            context.pdf.advance(marginBottom)
        }
    }
}

// MARK: - Dynamic Dispatch Support

extension HTML.Styled: _HTMLStyledContent where Content: HTML.View {
    public var styledProperty: Any? { property }

    package var wrappedStyledContent: (any _HTMLStyledContent)? {
        content as? any _HTMLStyledContent
    }

    public func renderWrappedContent(context: inout PDF.HTML.Context) {
        PDF.HTML.renderHTMLView(content, context: &context)
    }

    public func applyStyle(to context: inout PDF.HTML.Context) -> (avoidBreakAfter: Bool, forceBreakAfter: Bool, avoidBreakInside: Bool) {
        var avoidBreakAfter = false
        var forceBreakAfter = false
        var avoidBreakInside = false

        if let property = property {
            // Check for PDF context modifier
            if let modifier = property as? any PDF.HTML.StyleModifier {
                modifier.apply(to: &context.pdf, configuration: context.configuration)
            }
            // Check for HTML context modifier (for page-break-after, break-inside, etc.)
            if let htmlModifier = property as? any PDF.HTML.HTMLContextStyleModifier {
                htmlModifier.apply(to: &context)
            }

            // Capture and reset break flags
            if context.avoidPageBreakAfter {
                avoidBreakAfter = true
                context.avoidPageBreakAfter = false
            }
            if context.forcePageBreakAfter {
                forceBreakAfter = true
                context.forcePageBreakAfter = false
            }
            if context.avoidPageBreakInside {
                avoidBreakInside = true
                context.avoidPageBreakInside = false
            }
        }

        return (avoidBreakAfter, forceBreakAfter, avoidBreakInside)
    }

    public func _renderStyledDynamically(context: inout PDF.HTML.Context) {
        // This method should NOT be called directly anymore when flattening is active.
        // It's kept for compatibility but the flattening logic in renderHTMLView handles
        // consecutive HTML.Styled layers iteratively to avoid stack overflow.
        //
        // If called directly (e.g., for a single non-nested HTML.Styled), we delegate
        // to the flattened rendering path which handles all cases.
        PDF.HTML.renderFlattenedStyledContent(self, context: &context)
    }
}
