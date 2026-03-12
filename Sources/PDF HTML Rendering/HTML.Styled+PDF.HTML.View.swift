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
            if let property = view.property {
                if let modifier = property as? any PDF.HTML.StyleModifier {
                    modifier.apply(to: &context.pdf, configuration: context.configuration)
                }
                if let htmlModifier = property as? any PDF.HTML.HTMLContextStyleModifier {
                    htmlModifier.apply(to: &context)
                }
            }

            let breakFlags = context.captureBreakFlags()

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
            if breakFlags.avoidInside {
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
            if breakFlags.avoidAfter {
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

                if breakFlags.forceAfter {
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
    package var wrappedStyledContent: (any _HTMLStyledContent)? {
        content as? any _HTMLStyledContent
    }

    public func renderWrappedContent(context: inout PDF.HTML.Context) {
        PDF.HTML.renderHTMLView(content, context: &context)
    }

    public func applyStyle(to context: inout PDF.HTML.Context) -> PDF.HTML.Context.BreakFlags {
        if let property = property {
            if let modifier = property as? any PDF.HTML.StyleModifier {
                modifier.apply(to: &context.pdf, configuration: context.configuration)
            }
            if let htmlModifier = property as? any PDF.HTML.HTMLContextStyleModifier {
                htmlModifier.apply(to: &context)
            }
        }
        return context.captureBreakFlags()
    }
}
