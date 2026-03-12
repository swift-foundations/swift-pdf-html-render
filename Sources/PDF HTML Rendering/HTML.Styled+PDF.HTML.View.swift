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
        context.withSavedStyleState { context in
            // Check for break-related styles
            var shouldAvoidPageBreakAfter = false
            var shouldForcePageBreakAfter = false
            var shouldAvoidPageBreakInside = false

            if let property = view.property {
                if let modifier = property as? any PDF.HTML.StyleModifier {
                    modifier.apply(to: &context.pdf, configuration: context.configuration)
                }
                if let htmlModifier = property as? any PDF.HTML.HTMLContextStyleModifier {
                    htmlModifier.apply(to: &context)
                }

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
            if let marginTop = context.pdf.marginTop, marginTop.rawValue > 0 {
                context.pdf.advance(marginTop)
            }
            if let marginLeft = context.pdf.marginLeft {
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + marginLeft
            }
            if let marginRight = context.pdf.marginRight {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - marginRight
            }

            if let paddingTop = context.pdf.paddingTop, paddingTop.rawValue > 0 {
                context.pdf.advance(paddingTop)
            }
            if let paddingLeft = context.pdf.paddingLeft {
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + paddingLeft
            }
            if let paddingRight = context.pdf.paddingRight {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - paddingRight
            }

            if let explicitWidth = context.pdf.explicitWidth {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.llx + explicitWidth
            }

            // Handle break-inside: avoid
            if shouldAvoidPageBreakInside {
                let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
                let configuration = context.configuration
                let pendingBottomMargin = context.pendingBottomMargin

                let measuredHeight = context.pdf.measure { measureContext in
                    var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                    tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                    snapshot.restore(to: &tempHTMLContext.pdf)
                    Content._render(view.content, context: &tempHTMLContext)
                    tempHTMLContext.pdf.flushInlineRuns()
                    measureContext.layoutBox.lly = tempHTMLContext.pdf.layoutBox.lly
                }

                let pageContentHeight = context.configuration.content.height
                if context.pdf.wouldExceedPage(adding: measuredHeight) && measuredHeight <= pageContentHeight {
                    context.pdf.startNewPage()
                }
            }

            // Handle break-after: avoid (sticky header behavior)
            if shouldAvoidPageBreakAfter {
                let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
                let configuration = context.configuration
                let pendingBottomMargin = context.pendingBottomMargin

                let measuredHeight = context.pdf.measure { measureContext in
                    var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                    tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                    snapshot.restore(to: &tempHTMLContext.pdf)
                    Content._render(view.content, context: &tempHTMLContext)
                    tempHTMLContext.pdf.flushInlineRuns()
                    measureContext.layoutBox.lly = tempHTMLContext.pdf.layoutBox.lly
                }

                if let existingDeferred = context.deferredKeepWithNextRender {
                    let combinedHeight = existingDeferred.measuredHeight + measuredHeight
                    context.deferredKeepWithNextRender = PDF.HTML.Context.DeferredRender(
                        render: { ctx in
                            existingDeferred.render(&ctx)
                            snapshot.restore(to: &ctx.pdf)
                            Content._render(view.content, context: &ctx)
                            ctx.pdf.flushInlineRuns()
                        },
                        measuredHeight: combinedHeight
                    )
                } else {
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
                Content._render(view.content, context: &context)

                if shouldForcePageBreakAfter {
                    context.pdf.flushInlineRuns()
                    context.pdf.startNewPage()
                }
            }

            // Apply bottom padding and margin after content renders
            if let paddingBottom = context.pdf.paddingBottom, paddingBottom.rawValue > 0 {
                context.pdf.advance(paddingBottom)
            }
            if let marginBottom = context.pdf.marginBottom, marginBottom.rawValue > 0 {
                context.pdf.advance(marginBottom)
            }
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
