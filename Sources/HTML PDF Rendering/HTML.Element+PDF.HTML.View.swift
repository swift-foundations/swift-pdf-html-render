// HTML.Element+PDF.HTML.View.swift
// HTML.Element rendering using runtime tag metadata

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension HTML.Element: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Handle void elements (br, hr, etc.) based on runtime check
        if view.isVoid {
            renderVoidElement(view, context: &context)
            return
        }

        // Determine if this is a block or inline element
        let isBlock = view.isBlock

        // Save current style and horizontal bounds (NOT Y position - that must advance)
        let savedStyle = context.pdf.style
        let savedLLX = context.pdf.layoutBox.llx
        let savedURX = context.pdf.layoutBox.urx
        let savedPreserveWhitespace = context.pdf.preserveWhitespace

        // Apply tag-specific style BEFORE calculating margins
        // CSS `em` units in margins are relative to the element's own font size
        applyTagStyle(view.tagName, context: &context)

        // Check for block margins (now using the element's font size for em calculations)
        // Nested lists have no margins per CSS spec
        let isNestedList = (view.tagName == "ul" || view.tagName == "ol") && context.pdf.listDepth > 0
        let marginTop: PDF.UserSpace.Unit
        let marginBottom: PDF.UserSpace.Unit
        if !isNestedList, let margins = blockMargins(for: view.tagName, configuration: context.configuration) {
            marginTop = PDF.UserSpace.Unit(
                margins.top,
                currentSize: context.pdf.style.fontSize,
                baseFontSize: context.configuration.defaultFontSize
            )
            marginBottom = PDF.UserSpace.Unit(
                margins.bottom,
                currentSize: context.pdf.style.fontSize,
                baseFontSize: context.configuration.defaultFontSize
            )
        } else {
            marginTop = 0
            marginBottom = 0
        }

        // If there's deferred content (from page-break-after: avoid) and we're rendering a block element
        if isBlock, let deferred = context.deferredKeepWithNextRender {
            // Clear deferred content - we're handling it now
            context.deferredKeepWithNextRender = nil

            // If the deferred header is very tall (> 90% of page), skip sticky behavior
            let availablePageHeight = context.pdf.remainingHeight
            if deferred.measuredHeight.value > availablePageHeight.value * 0.9 {
                // Just render the header without sticky behavior
                deferred.render(&context)
                renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, context: &context)
                // Restore style
                context.pdf.style = savedStyle
                context.pdf.layoutBox.llx = savedLLX
                context.pdf.layoutBox.urx = savedURX
                context.pdf.preserveWhitespace = savedPreserveWhitespace
                return
            }

            // Calculate minimum content height (at least one line + top margin)
            let oneLineHeight = context.pdf.style.lineHeightPoints
            let minContentHeight = marginTop + oneLineHeight.value
            let totalNeeded = PDF.UserSpace.Height(deferred.measuredHeight.value + minContentHeight)

            // Check if header + minimum content fits on current page
            if context.pdf.wouldExceedPage(adding: totalNeeded) {
                // Start new page BEFORE rendering the header
                context.pdf.startNewPage()
            }

            // Now render the deferred header
            deferred.render(&context)

            // Continue with normal rendering of this element
            renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, context: &context)
            // Restore style
            context.pdf.style = savedStyle
            context.pdf.layoutBox.llx = savedLLX
            context.pdf.layoutBox.urx = savedURX
            context.pdf.preserveWhitespace = savedPreserveWhitespace
            return
        }

        // Render with flow and margins
        renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, context: &context)

        // Restore style and horizontal bounds (Y position stays advanced)
        context.pdf.style = savedStyle
        context.pdf.layoutBox.llx = savedLLX
        context.pdf.layoutBox.urx = savedURX
        context.pdf.preserveWhitespace = savedPreserveWhitespace
    }

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
            let spacing = context.configuration.defaultFontSize * 0.5
            context.pdf.advance(PDF.UserSpace.Y(spacing))

            let lineY = context.pdf.layoutBox.lly
            let startX = context.pdf.layoutBox.llx
            let endX = PDF.UserSpace.X(startX.value + context.pdf.layoutBox.width.value)

            context.pdf.emitLine(
                from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
                to: PDF.UserSpace.Coordinate(x: endX, y: lineY),
                color: .gray(0.5),
                width: 1
            )

            context.pdf.advance(PDF.UserSpace.Y(spacing))
        default:
            // Other void elements have no PDF representation
            break
        }
    }

    /// Render with flow (block or inline) and margins
    private static func renderWithFlow(
        _ view: Self,
        isBlock: Bool,
        marginTop: PDF.UserSpace.Unit,
        marginBottom: PDF.UserSpace.Unit,
        context: inout PDF.HTML.Context
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
            if marginTop > 0 || marginBottom > 0 {
                context.applyCollapsedMargin(top: marginTop, bottom: marginBottom)
            }

            // Handle list containers (ol, ul)
            if let listType = listType(for: view.tagName) {
                context.pdf.push(list: listType)
                // WebKit's default padding-left for ul/ol is 40px ≈ 30pt at 72dpi
                let indent: PDF.UserSpace.Unit = 30
                let savedLLX = context.pdf.layoutBox.llx
                context.pdf.layoutBox.llx = PDF.UserSpace.X(savedLLX.value + indent)

                // Reset margin collapsing for list content - CSS margins don't collapse
                // between a parent and its first/last child when there's padding/border
                // (the list indent acts like padding, preventing collapse)
                let savedPendingMargin = context.pendingBottomMargin
                context.pendingBottomMargin = 0

                PDF.HTML.renderBlock(view.content, context: &context)

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
                let markerWidth: PDF.UserSpace.Unit
                switch marker {
                case .text(let bytes, let font):
                    markerWidth = font.winAnsi.width(of: bytes, atSize: context.pdf.style.fontSize)
                case .strokedCircle(let circle, _):
                    markerWidth = circle.radius.value * 2  // diameter
                case .filledCircle(let circle):
                    markerWidth = circle.radius.value * 2  // diameter
                case .filledSquare(let rect):
                    markerWidth = rect.width.value
                }

                // Position marker so its right edge has a consistent gap before text
                // Gap is 0.5em (proportional to font size) for uniform appearance
                let markerGap = context.pdf.style.fontSize * 0.5
                let markerX = PDF.UserSpace.X(context.pdf.layoutBox.llx.value - markerWidth - markerGap)

                // Set pending marker to be rendered with the first line of text
                // This ensures the marker aligns with actual text content even when
                // the list item contains block elements with margins (like <p>)
                context.pdf.pendingListMarker = (marker: marker, x: markerX)

                // Render content - marker will be emitted when first text line renders
                PDF.HTML.renderBlock(view.content, context: &context)

                // Clear any remaining pending marker (in case the list item was empty)
                context.pdf.pendingListMarker = nil
            }
            else {
                PDF.HTML.renderBlock(view.content, context: &context)
            }
        } else {
            // Handle inline quotation (q) with curly quotes
            if view.tagName == "q" {
                // Insert opening curly quote
                let openQuote = PDF.Text.Run(
                    bytes: [0x93],  // LEFT DOUBLE QUOTATION MARK in WinAnsi
                    font: context.pdf.style.font,
                    fontSize: context.pdf.style.fontSize,
                    color: context.pdf.style.color,
                    textDecoration: context.pdf.style.textMarkup,
                    verticalOffset: context.pdf.style.verticalOffset
                )
                context.pdf.append(inline: openQuote)

                PDF.HTML.renderInline(view.content, context: &context)

                // Insert closing curly quote
                let closeQuote = PDF.Text.Run(
                    bytes: [0x94],  // RIGHT DOUBLE QUOTATION MARK in WinAnsi
                    font: context.pdf.style.font,
                    fontSize: context.pdf.style.fontSize,
                    color: context.pdf.style.color,
                    textDecoration: context.pdf.style.textMarkup,
                    verticalOffset: context.pdf.style.verticalOffset
                )
                context.pdf.append(inline: closeQuote)
            } else {
                PDF.HTML.renderInline(view.content, context: &context)
            }
        }
    }

    /// Check if tag is a list container
    private static func isListContainer(_ tagName: String) -> Bool {
        tagName == "ol" || tagName == "ul"
    }

    /// Get list type for a list container tag
    private static func listType(for tagName: String) -> PDF.Context.ListType? {
        switch tagName {
        case "ol": return .ordered(startNumber: 1)
        case "ul": return .unordered
        default: return nil
        }
    }

    /// Apply tag-specific styling based on tag name
    private static func applyTagStyle(_ tagName: String, context: inout PDF.HTML.Context) {
        switch tagName {
        // Headings
        case "h1":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 1)
        case "h2":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 2)
        case "h3":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 3)
        case "h4":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 4)
        case "h5":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 5)
        case "h6":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 6)

        // Emphasis and importance
        case "strong", "b":
            context.pdf.style.font = context.pdf.style.font.bold
        case "em", "i":
            context.pdf.style.font = context.pdf.style.font.italic

        // Code and preformatted
        // WebKit uses a smaller monospace font relative to body text
        case "code", "kbd", "samp":
            context.pdf.style.font = .courier
            // WebKit's monospace is slightly smaller than body text
            context.pdf.style.fontSize = (context.pdf.style.fontSize) * 0.9
        case "pre":
            context.pdf.style.font = .courier
            context.pdf.style.fontSize = (context.pdf.style.fontSize) * 0.9
            context.pdf.preserveWhitespace = true

        // Text decoration
        case "s", "strike", "del":
            context.pdf.style.textMarkup = .strikeout
        case "u", "ins":
            context.pdf.style.textMarkup = .underline
        case "mark":
            context.pdf.style.textMarkup = .highlight(PDF.Color.yellow)

        // Sub/superscript
        // WebKit: font-size ~0.83em, vertical-align: sub/super
        case "sub":
            let currentSize = context.pdf.style.fontSize
            context.pdf.style.fontSize = currentSize * 0.83
            // Subscript drops below baseline - WebKit uses about 0.2em
            context.pdf.style.verticalOffset = (context.pdf.style.verticalOffset) - currentSize * 0.2
        case "sup":
            let currentSize = context.pdf.style.fontSize
            context.pdf.style.fontSize = currentSize * 0.83
            // Superscript rises above baseline - WebKit uses about 0.4em
            context.pdf.style.verticalOffset = (context.pdf.style.verticalOffset) + currentSize * 0.4

        // Small - WebKit default is smaller (13px base = ~0.8125em)
        case "small":
            context.pdf.style.fontSize = context.pdf.style.fontSize * 0.83

        // Links
        case "a":
            context.pdf.style.color = .blue
            context.pdf.style.textMarkup = .underline

        // Block indentation
        // WebKit default margin-left for blockquote is 40px = 30pt (at 72/96 conversion)
        case "blockquote", "dd":
            let indent: PDF.UserSpace.Unit = 30
            context.pdf.layoutBox.llx = PDF.UserSpace.X(context.pdf.layoutBox.llx.value + indent)
        case "figure":
            let margin: PDF.UserSpace.Unit = 40
            context.pdf.layoutBox.llx = PDF.UserSpace.X(context.pdf.layoutBox.llx.value + margin)
            context.pdf.layoutBox.urx = PDF.UserSpace.X(context.pdf.layoutBox.urx.value - margin)

        // Citation, definition, and variable (all italic in WebKit)
        case "cite", "dfn", "var":
            context.pdf.style.font = context.pdf.style.font.italic

        default:
            break
        }
    }

    /// Get block margins for a tag name
    private static func blockMargins(
        for tagName: String,
        configuration: PDF.HTML.Configuration
    ) -> (top: LengthPercentage, bottom: LengthPercentage)? {
        switch tagName {
        case "p":
            return (.length(.em(1.0)), .length(.em(1.0)))
        case "h1":
            return (.length(.em(0.67)), .length(.em(0.67)))
        case "h2":
            return (.length(.em(0.83)), .length(.em(0.83)))
        case "h3":
            return (.length(.em(1.0)), .length(.em(1.0)))
        case "h4":
            return (.length(.em(1.33)), .length(.em(1.33)))
        case "h5":
            return (.length(.em(1.67)), .length(.em(1.67)))
        case "h6":
            return (.length(.em(2.33)), .length(.em(2.33)))
        case "blockquote":
            return (.length(.em(1.0)), .length(.em(1.0)))
        // Note: <figure> has no vertical margins - its children provide spacing.
        // This matches WebKit behavior where figure acts as a transparent container
        // for margin collapsing, with only horizontal indentation applied.
        case "pre":
            return (.length(.em(1.0)), .length(.em(1.0)))
        case "ul", "ol":
            // Note: nested lists have no margins (handled by parent li element)
            return (.length(.em(1.0)), .length(.em(1.0)))
        // Note: <li> has no default margins per WHATWG HTML Standard
        // The parent <ul>/<ol> provides the 1em margins
        default:
            return nil
        }
    }
}
