// HTML.Element+PDF.HTML.View.swift
// HTML.Element rendering using runtime tag metadata

import CSS_Standard
import Dimension_Primitives
import HTML_Renderable
import Layout_Primitives
import Dictionary_Primitives
import PDF_Rendering
import WHATWG_HTML

// MARK: - Static Dispatch Conformance

extension HTML.Element.Tag: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        renderTag(
            view,
            context: &context,
            renderBlock: { content, ctx in PDF.HTML.Render.block(content, context: &ctx) },
            renderInline: { content, ctx in PDF.HTML.Render.inline(content, context: &ctx) }
        )
    }
}

// MARK: - Shared Helpers (no Content constraint needed)
// These helper methods are extracted to an unconstrained extension so they can be
// called from both the static dispatch path (Content: PDF.HTML.View) and the
// dynamic dispatch path (Content: HTML.View).

extension HTML.Element.Tag {
    /// Render void element (br, hr, etc.)
    private static func renderVoidElement(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        switch view.tagName {
        case "br":
            // BR is inline, just flush and advance within the current block
            context.pdf.flushInlineRuns()
            context.pdf.advanceLine()
        case "hr":
            // HR is block-level - flush inline runs first
            if context.pdf.hasInlineRuns {
                context.pdf.flushInlineRuns()
            }
            let spacing = (context.configuration.defaultFontSize * context.configuration.horizontalGapEm).height
            context.pdf.advance(spacing)

            let layoutBox = context.pdf.layoutBox
            context.pdf.emitLine(
                from: PDF.UserSpace.Coordinate(x: layoutBox.llx, y: layoutBox.lly),
                to: PDF.UserSpace.Coordinate(x: layoutBox.urx, y: layoutBox.lly),
                color: .gray(0.5),
                width: .init(1)
            )

            context.pdf.advance(spacing)
        default:
            // Other void elements have no PDF representation
            break
        }
    }
}

// MARK: - Unified Rendering (parameterized on block/inline dispatch)

extension HTML.Element.Tag {
    /// Unified tag rendering, parameterized on how child content is dispatched.
    ///
    /// Both the static (`PDF.HTML.View`) and dynamic (`HTML.View`) entry points
    /// delegate here, supplying the appropriate `renderBlock`/`renderInline` closures.
    static func renderTag(
        _ view: Self,
        context: inout PDF.HTML.Context,
        renderBlock: (Content?, inout PDF.HTML.Context) -> Void,
        renderInline: (Content?, inout PDF.HTML.Context) -> Void
    ) {
        // Handle void elements (br, hr, etc.) based on runtime check
        if view.isVoid {
            renderVoidElement(view, context: &context)
            return
        }

        // Determine if this is a block or inline element
        let isBlock = view.isBlock

        // Save element-scoped state (restored via defer)
        // NOTE: Y position is NOT saved - it must advance through rendering
        let savedStyle = context.pdf.style
        let savedLLX = context.pdf.layoutBox.llx
        let savedURX = context.pdf.layoutBox.urx
        let savedPreserveWhitespace = context.pdf.preserveWhitespace
        let savedLinkURL = context.link.currentURL
        let savedInternalLinkId = context.link.currentInternalId

        defer {
            context.pdf.style = savedStyle
            context.pdf.layoutBox.llx = savedLLX
            context.pdf.layoutBox.urx = savedURX
            context.pdf.preserveWhitespace = savedPreserveWhitespace
            context.link.currentURL = savedLinkURL
            context.link.currentInternalId = savedInternalLinkId
        }

        // Apply tag-specific style BEFORE calculating margins
        // CSS `em` units in margins are relative to the element's own font size
        applyTagStyle(view.tagName, context: &context)

        // Collect heading text for bookmarks (position captured after margin/page-break handling)
        var pendingHeading: (level: Int, text: String)? = nil
        if let headingLevel = headingLevel(for: view.tagName) {
            let headingText = extractCellText(from: view.content)
            if !headingText.isEmpty {
                pendingHeading = (level: headingLevel, text: headingText)
            }
        }

        // For anchor tags, extract href from attributes for clickable links
        if view.tagName == "a" {
            if let href = context.attributes["href"] {
                if href.hasPrefix("#") {
                    // Internal link - store the target ID (without #)
                    context.link.currentInternalId = String(href.dropFirst())
                } else {
                    // External link - store the full URL
                    context.link.currentURL = href
                }
            }
        }

        // Collect named destination for elements with id attribute (for internal links)
        if let elementId = context.attributes["id"], !elementId.isEmpty {
            // Use completedPages.count + 1 for correct 1-indexed page number
            // pages.count includes current page if non-empty, which would overcount
            let pageNumber = context.pdf.completedPages.count + 1
            let yPosition = context.pdf.layoutBox.lly
            context.link.destinations[elementId] = PDF.HTML.Context.Link.Destination(
                pageNumber: pageNumber,
                yPosition: yPosition
            )
        }

        // Check for block margins (now using the element's font size for em calculations)
        // Nested lists have no margins per CSS spec
        let isNestedList = (view.tagName == "ul" || view.tagName == "ol") && context.pdf.listDepth > 0
        let marginTop: PDF.UserSpace.Height
        let marginBottom: PDF.UserSpace.Height
        if !isNestedList, let margins = blockMargins(for: view.tagName, configuration: context.configuration) {
            let currentSize = context.pdf.style.fontSize
            marginTop = PDF.UserSpace.Size<1>(
                margins.top,
                currentSize: currentSize,
                baseFontSize: context.configuration.defaultFontSize
            ).height
            marginBottom = PDF.UserSpace.Size<1>(
                margins.bottom,
                currentSize: currentSize,
                baseFontSize: context.configuration.defaultFontSize
            ).height
        } else {
            marginTop = .init(0)
            marginBottom = .init(0)
        }

        // If there's deferred content (from page-break-after: avoid) and we're rendering a block element
        if isBlock, let deferred = context.deferredKeepWithNextRender {
            // Clear deferred content - we're handling it now
            context.deferredKeepWithNextRender = nil

            // If the deferred header is very tall (> threshold % of full page), skip sticky behavior
            let fullPageHeight = context.configuration.content.height
            if deferred.measuredHeight > fullPageHeight * context.configuration.deferredHeaderThreshold {
                // Just render the header without sticky behavior
                deferred.render(&context)
                renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, pendingHeading: pendingHeading, context: &context, renderBlock: renderBlock, renderInline: renderInline)
                return
            }

            // Calculate minimum content height (at least one line + top margin)
            let oneLineHeight = context.pdf.style.line.height
            let minContentHeight = marginTop + oneLineHeight
            let totalNeeded = deferred.measuredHeight + minContentHeight

            // Check if header + minimum content fits on current page
            if context.pdf.wouldExceedPage(adding: totalNeeded) {
                // Start new page BEFORE rendering the header
                context.pdf.startNewPage()
            }

            // Now render the deferred header
            deferred.render(&context)

            // Continue with normal rendering of this element
            renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, pendingHeading: pendingHeading, context: &context, renderBlock: renderBlock, renderInline: renderInline)
            return
        }

        // Render with flow and margins
        renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, pendingHeading: pendingHeading, context: &context, renderBlock: renderBlock, renderInline: renderInline)
    }

    /// Render with flow (block or inline) and margins
    private static func renderWithFlow(
        _ view: Self,
        isBlock: Bool,
        marginTop: PDF.UserSpace.Height,
        marginBottom: PDF.UserSpace.Height,
        pendingHeading: (level: Int, text: String)?,
        context: inout PDF.HTML.Context,
        renderBlock: (Content?, inout PDF.HTML.Context) -> Void,
        renderInline: (Content?, inout PDF.HTML.Context) -> Void
    ) {
        if isBlock {
            // Block elements must flush any pending inline content before rendering
            if context.pdf.hasInlineRuns {
                context.pdf.flushInlineRuns()
            }

            // Only apply margin collapsing if this element has margins.
            // Semantic containers (article, section, header, footer, etc.) have no margins
            // and should be "transparent" to margin collapsing per CSS spec - margins collapse
            // between a parent and its first/last child when there's no padding/border.
            if marginTop > .init(0) || marginBottom > .init(0) {
                context.applyCollapsedMargin(top: marginTop, bottom: marginBottom)
            }

            // NOW capture heading position - after margin/page-break handling
            if let heading = pendingHeading {
                // IMPORTANT: Check for page break BEFORE capturing position
                // The heading's line height depends on its font size, which is larger than body text
                // If we don't check here, we might record page N but the heading renders on page N+1
                let headingFontSize = context.configuration.headingSize(level: heading.level)
                let headingLineHeight = (headingFontSize * context.pdf.style.lineHeight).height
                context.pdf.checkPageBreak(needing: headingLineHeight)

                // Use completedPages.count + 1 for correct 1-indexed page number
                // pages.count includes current page if non-empty, which would overcount
                let pageNumber = context.pdf.completedPages.count + 1
                let yPosition = context.pdf.layoutBox.lly

                context.section.headings.append(PDF.HTML.Context.Section.HeadingEntry(
                    level: heading.level,
                    text: heading.text,
                    pageNumber: pageNumber,
                    yPosition: yPosition
                ))

                // For H1-H3, update section tracking for headers/footers
                if heading.level <= 3 {
                    context.section.currentTitle = heading.text
                    if context.section.pageTitles[pageNumber] == nil {
                        context.section.pageTitles[pageNumber] = heading.text
                    }
                }
            }

            // Handle table containers
            if view.tagName == "table" {
                renderTable(view, context: &context, renderBlock: renderBlock)
            }
            // Handle table sections (thead, tbody, tfoot)
            else if view.tagName == "thead" {
                // Start capturing header cells for repetition on page breaks
                context.with(\.table) { tc in
                    tc.header.startCapturing()
                }

                renderBlock(view.content, &context)

                // Finish capturing header and store for page break repetition
                context.with(\.table) { tc in
                    tc.header.finalizeCapture()
                    // Store header row height for page break calculations
                    if !tc.rowHeights.isEmpty {
                        tc.header.rowHeight = tc.rowHeights[0]
                    }
                }
            }
            else if view.tagName == "tbody" || view.tagName == "tfoot" {
                // Pass-through: table sections just render their content
                renderBlock(view.content, &context)
            }
            // Handle table rows (tr)
            else if view.tagName == "tr" {
                renderTableRow(view, context: &context, renderBlock: renderBlock)
            }
            // Handle table cells (td, th)
            else if view.tagName == "td" || view.tagName == "th" {
                renderTableCell(view, isHeader: view.tagName == "th", context: &context, renderInline: renderInline)
            }
            // Handle list containers (ol, ul)
            else if let listType = listType(for: view.tagName) {
                context.pdf.push(list: listType)
                // WebKit's default padding-left for ul/ol is 40px ≈ 30pt at 72dpi
                let indent = context.configuration.indent.list
                let savedLLX = context.pdf.layoutBox.llx
                context.pdf.layoutBox.llx = savedLLX + indent

                // Reset margin collapsing for list content - CSS margins don't collapse
                // between a parent and its first/last child when there's padding/border
                // (the list indent acts like padding, preventing collapse)
                let savedPendingMargin = context.pendingBottomMargin
                context.pendingBottomMargin = .init(0)

                renderBlock(view.content, &context)

                // Restore the pending margin for siblings after this list
                context.pendingBottomMargin = savedPendingMargin

                context.pdf.layoutBox.llx = savedLLX
                context.pdf.popList()
            }
            // Handle list items (li)
            else if view.tagName == "li" {
                // Get the marker
                let marker = context.pdf.nextListMarker()

                // Calculate marker width based on marker type
                let markerWidth: PDF.UserSpace.Width
                switch marker {
                case .text(let bytes, let font):
                    markerWidth = font.winAnsi.width(of: bytes, atSize: context.pdf.style.fontSize)
                case .strokedCircle(let circle, _):
                    markerWidth = circle.diameter.width
                case .filledCircle(let circle):
                    markerWidth = circle.diameter.width
                case .filledSquare(let rect):
                    markerWidth = rect.width
                }

                // Position marker so its right edge has a consistent gap before text
                // Gap is proportional to font size for uniform appearance
                let markerGap = (context.pdf.style.fontSize * context.configuration.horizontalGapEm).width
                let markerX = context.pdf.layoutBox.llx - markerWidth - markerGap

                // Set pending marker to be rendered with the first line of text
                // This ensures the marker aligns with actual text content even when
                // the list item contains block elements with margins (like <p>)
                context.pdf.pendingListMarker = (marker: marker, x: markerX)

                // Render content - marker will be emitted when first text line renders
                renderBlock(view.content, &context)

                // Clear any remaining pending marker (in case the list item was empty)
                context.pdf.pendingListMarker = nil
            }
            else {
                renderBlock(view.content, &context)
            }
        } else {
            // Handle inline quotation (q) with curly quotes
            if view.tagName == "q" {
                // Insert opening curly quote
                let openQuote = PDF.Context.TextRun(
                    bytes: [0x93],  // LEFT DOUBLE QUOTATION MARK in WinAnsi
                    font: context.pdf.style.font,
                    fontSize: context.pdf.style.fontSize,
                    color: context.pdf.style.color,
                    textDecoration: context.pdf.style.textMarkup,
                    verticalOffset: context.pdf.style.verticalOffset
                )
                context.pdf.append(inline: openQuote)

                renderInline(view.content, &context)

                // Insert closing curly quote
                let closeQuote = PDF.Context.TextRun(
                    bytes: [0x94],  // RIGHT DOUBLE QUOTATION MARK in WinAnsi
                    font: context.pdf.style.font,
                    fontSize: context.pdf.style.fontSize,
                    color: context.pdf.style.color,
                    textDecoration: context.pdf.style.textMarkup,
                    verticalOffset: context.pdf.style.verticalOffset
                )
                context.pdf.append(inline: closeQuote)
            } else {
                renderInline(view.content, &context)
            }
        }
    }
}

// MARK: - Dynamic Dispatch Support for HTML.Element.Tag

/// Conformance to `_HTMLElementContent` enables runtime dispatch for `HTML.Element.Tag<Content>`
/// when `Content` doesn't statically conform to `PDF.HTML.View` but is an `HTML.View`.
///
/// This mirrors the static dispatch `_render` method but uses dynamic dispatch helpers
/// (`Render.Dynamic.block`, `Render.Dynamic.inline`) for content rendering.
extension HTML.Element.Tag: _HTMLElementContent where Content: HTML.View {
    public func _renderElementDynamically(context: inout PDF.HTML.Context) {
        Self.renderTag(
            self,
            context: &context,
            renderBlock: { content, ctx in PDF.HTML.Render.Dynamic.block(content, context: &ctx) },
            renderInline: { content, ctx in PDF.HTML.Render.Dynamic.inline(content, context: &ctx) }
        )
    }
}
