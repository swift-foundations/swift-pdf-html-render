// HTML.Styled+PDF.HTML.View.swift
// PDF rendering support for HTML.Styled CSS wrapper

import HTML_Renderable
import PDF_Rendering
import W3C_CSS_Shared

/// PDF rendering for HTML.Styled elements.
///
/// When rendering HTML to PDF, inline styles that conform to `PDF.HTML.Style.Modifier`
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
                if let modifier = property as? any PDF.HTML.Style.Modifier {
                    modifier.apply(to: &context.pdf, configuration: context.configuration)
                }
                if let htmlModifier = property as? any PDF.HTML.Style.Context.Modifier {
                    htmlModifier.apply(to: &context)
                }
            }

            let breakFlags = context.captureBreakFlags()

            // Apply CSS Box Model
            if let marginTop = context.pdf.marginTop, marginTop > .zero {
                context.pdf.advance(marginTop)
            }
            if let marginLeft = context.pdf.marginLeft {
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + marginLeft
            }
            if let marginRight = context.pdf.marginRight {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - marginRight
            }

            if let paddingTop = context.pdf.paddingTop, paddingTop > .zero {
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
                let measuredHeight = context.measureContentHeight { ctx in
                    Content._render(view.content, context: &ctx)
                }

                let pageContentHeight = context.configuration.content.height
                if context.pdf.page.exceeds(adding: measuredHeight) && measuredHeight <= pageContentHeight {
                    context.pdf.page.new()
                }
            }

            // Handle break-after: avoid (sticky header behavior)
            if breakFlags.avoidAfter {
                let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
                let measuredHeight = context.measureContentHeight { ctx in
                    Content._render(view.content, context: &ctx)
                }

                if let existingDeferred = context.deferredKeepWithNextRender {
                    let combinedHeight = existingDeferred.measuredHeight + measuredHeight
                    context.deferredKeepWithNextRender = PDF.HTML.Context.Deferred(
                        render: { ctx in
                            existingDeferred.render(&ctx)
                            snapshot.restore(to: &ctx.pdf)
                            Content._render(view.content, context: &ctx)
                            ctx.pdf.flush.inline()
                        },
                        measuredHeight: combinedHeight
                    )
                } else {
                    context.deferredKeepWithNextRender = PDF.HTML.Context.Deferred(
                        render: { ctx in
                            snapshot.restore(to: &ctx.pdf)
                            Content._render(view.content, context: &ctx)
                            ctx.pdf.flush.inline()
                        },
                        measuredHeight: measuredHeight
                    )
                }
            } else {
                Content._render(view.content, context: &context)

                if breakFlags.forceAfter {
                    context.pdf.flush.inline()
                    context.pdf.page.new()
                }
            }

            // Apply bottom padding and margin after content renders
            if let paddingBottom = context.pdf.paddingBottom, paddingBottom > .zero {
                context.pdf.advance(paddingBottom)
            }
            if let marginBottom = context.pdf.marginBottom, marginBottom > .zero {
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

    public func applyStyle(to context: inout PDF.HTML.Context) -> PDF.HTML.Context.Break {
        if let property = property {
            if let modifier = property as? any PDF.HTML.Style.Modifier {
                modifier.apply(to: &context.pdf, configuration: context.configuration)
            }
            if let htmlModifier = property as? any PDF.HTML.Style.Context.Modifier {
                htmlModifier.apply(to: &context)
            }
        }
        return context.captureBreakFlags()
    }
}
