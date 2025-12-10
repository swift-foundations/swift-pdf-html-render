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

            // Handle table containers
            if view.tagName == "table" {
                renderTable(view, context: &context)
            }
            // Handle table sections (thead, tbody, tfoot)
            else if view.tagName == "thead" {
                // Start capturing header cells for repetition on page breaks
                if var tc = context.tableContext {
                    tc.isCapturingHeader = true
                    tc.pendingHeaderCells = []
                    context.tableContext = tc
                }

                PDF.HTML.renderBlock(view.content, context: &context)

                // Finish capturing header and store for page break repetition
                if var tc = context.tableContext {
                    tc.isCapturingHeader = false
                    tc.headerCells = tc.pendingHeaderCells
                    // Store header row height for page break calculations
                    if !tc.rowHeights.isEmpty {
                        tc.headerRowHeight = tc.rowHeights[0]
                    }
                    context.tableContext = tc
                }
            }
            else if view.tagName == "tbody" || view.tagName == "tfoot" {
                // Pass-through: table sections just render their content
                PDF.HTML.renderBlock(view.content, context: &context)
            }
            // Handle table rows (tr)
            else if view.tagName == "tr" {
                renderTableRow(view, context: &context)
            }
            // Handle table cells (td, th)
            else if view.tagName == "td" || view.tagName == "th" {
                renderTableCell(view, isHeader: view.tagName == "th", context: &context)
            }
            // Handle list containers (ol, ul)
            else if let listType = listType(for: view.tagName) {
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
                let openQuote = PDF.Context.TextRun(
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
        case "table":
            return (.length(.em(1.0)), .length(.em(1.0)))
        default:
            return nil
        }
    }

    // MARK: - Table Rendering

    /// Render a table element
    private static func renderTable(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Save current context state
        let savedTableContext = context.tableContext
        let tableStartY = context.pdf.layoutBox.lly

        // Get available width and configuration
        let availableWidth = context.pdf.layoutBox.width
        let cellPadding = context.configuration.tableCellPadding

        // Start with empty columns - will be populated dynamically on first row
        let columnWidths: [PDF.UserSpace.Width] = []

        // Estimate row height
        let defaultRowHeight = PDF.UserSpace.Height(context.pdf.style.lineHeightPoints.value + cellPadding * 2)
        let rowHeights: [PDF.UserSpace.Height] = []

        // Create table bounds
        let tableX = context.pdf.layoutBox.llx
        let tableBounds = PDF.UserSpace.Rectangle(
            x: tableX,
            y: tableStartY,
            width: availableWidth,
            height: defaultRowHeight
        )

        // Initialize table context
        context.tableContext = PDF.HTML.Context.Table(
            bounds: tableBounds,
            columnWidths: columnWidths,
            rowHeights: rowHeights,
            spanGrid: [],
            cellPadding: cellPadding,
            borderColor: context.configuration.tableBorderColor,
            borderWidth: context.configuration.tableBorderWidth,
            headerBackground: context.configuration.tableHeaderBackground,
            alternatingRowColor: context.configuration.tableAlternatingRowColor
        )
        // Track total rows for Y advancement
        context.tableContext?.totalRowsRendered = 0

        // Reset margin collapsing within table
        context.resetMarginCollapsing()

        // Render table content
        PDF.HTML.renderBlock(view.content, context: &context)

        // Draw deferred spanning cells (rowspan > 1)
        // These cells need borders that span multiple rows
        if let tc = context.tableContext {
            for deferred in tc.deferredSpanningCells {
                // Calculate total height across all spanned rows
                let startRow = deferred.originRow
                let endRow = startRow + deferred.rowspan
                var totalHeight: PDF.UserSpace.Unit = 0
                for rowIndex in startRow..<min(endRow, tc.rowHeights.count) {
                    totalHeight += tc.rowHeights[rowIndex].value
                }

                // Calculate cell bounds
                let cellX = tc.xForColumn(deferred.column)
                let cellWidth = tc.widthForColumns(deferred.column, count: deferred.colspan)
                let cellBounds = PDF.UserSpace.Rectangle(
                    x: cellX,
                    y: deferred.startY,
                    width: cellWidth,
                    height: PDF.UserSpace.Height(totalHeight)
                )

                // Draw background for spanning cell
                if deferred.isHeader, let headerBg = tc.headerBackground {
                    drawCellBackground(bounds: cellBounds, color: headerBg, borderWidth: tc.borderWidth, context: &context)
                }

                // Draw border for spanning cell
                drawCellBorder(bounds: cellBounds, tableCtx: tc, context: &context)
            }
        }

        // Advance past the table - use current layoutBox position which was updated by rows
        // Add a small gap after the table
        context.pdf.advance(PDF.UserSpace.Y(context.configuration.defaultFontSize * 0.5))

        // Restore context
        context.tableContext = savedTableContext
    }

    /// Render a table row
    private static func renderTableRow(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        guard var tableCtx = context.tableContext else {
            // Fallback: render as block if not in table context
            PDF.HTML.renderBlock(view.content, context: &context)
            return
        }

        // Reset for this row
        tableCtx.currentColumn = 0
        tableCtx.maxCellHeightInCurrentRow = PDF.UserSpace.Height(0)
        tableCtx.pendingCellBorders = []

        // Calculate minimum row height (single line)
        let minRowHeight = PDF.UserSpace.Height(context.pdf.style.lineHeightPoints.value + tableCtx.cellPadding * 2)

        // For page break check: account for header repetition if headers exist
        let headerHeight = tableCtx.headerCells != nil ? tableCtx.headerRowHeight : PDF.UserSpace.Height(0)
        let totalNeeded = PDF.UserSpace.Height(minRowHeight.value + headerHeight.value)

        // Check if row (plus header if needed) fits on current page
        let didPageBreak = context.pdf.checkPageBreak(needing: totalNeeded)

        // If page break occurred and we have stored headers, repeat them
        if didPageBreak && tableCtx.headerCells != nil && tableCtx.columnsInitialized {
            renderRepeatedHeader(context: &context)
            // Refresh tableCtx after header rendering
            if let tc = context.tableContext {
                tableCtx = tc
            }
        }

        // Update table bounds to use current layout position for this row
        tableCtx.bounds = PDF.UserSpace.Rectangle(
            x: tableCtx.bounds.llx,
            y: context.pdf.layoutBox.lly,
            width: tableCtx.bounds.width,
            height: minRowHeight
        )
        tableCtx.currentRow = 0

        context.tableContext = tableCtx

        // Save the current Y position for row start
        let rowStartY = context.pdf.layoutBox.lly

        // FIRST ROW: Two-pass rendering for column counting
        if !tableCtx.columnsInitialized {
            // Pass 1: Measurement - count columns only
            if var tc = context.tableContext {
                tc.measureOnly = true
                tc.currentColumn = 0
                context.tableContext = tc
            }
            PDF.HTML.renderBlock(view.content, context: &context)

            // After measurement, set up correct column widths
            if var tc = context.tableContext {
                tc.measureOnly = false
                tc.columnsInitialized = true
                let columnCount = tc.columnWidths.count
                if columnCount > 0 {
                    let equalWidth = PDF.UserSpace.Width(tc.bounds.width.value / PDF.UserSpace.Unit(columnCount))
                    tc.columnWidths = Array(repeating: equalWidth, count: columnCount)
                }
                // Reset for drawing pass
                tc.currentColumn = 0
                tc.maxCellHeightInCurrentRow = PDF.UserSpace.Height(0)
                tc.pendingCellBorders = []
                context.tableContext = tc
            }

            // Pass 2: Pre-draw backgrounds (using min height - will be redrawn if content is taller)
            if let tc = context.tableContext {
                for col in 0..<tc.columnCount {
                    let cellX = tc.xForColumn(col)
                    let cellWidth = tc.widthForColumns(col, count: 1)
                    let cellBounds = PDF.UserSpace.Rectangle(
                        x: cellX,
                        y: rowStartY,
                        width: cellWidth,
                        height: minRowHeight
                    )
                    // First row cells are typically headers
                    if let headerBg = tc.headerBackground {
                        drawCellBackground(bounds: cellBounds, color: headerBg, borderWidth: tc.borderWidth, context: &context)
                    }
                }
            }

            // Pass 3: Render content
            PDF.HTML.renderBlock(view.content, context: &context)
        } else {
            // Subsequent rows: Draw backgrounds first, then content
            if let tc = context.tableContext {
                for col in 0..<tc.columnCount {
                    let cellX = tc.xForColumn(col)
                    let cellWidth = tc.widthForColumns(col, count: 1)
                    let cellBounds = PDF.UserSpace.Rectangle(
                        x: cellX,
                        y: rowStartY,
                        width: cellWidth,
                        height: minRowHeight
                    )
                    if tc.totalRowsRendered % 2 == 1, let altColor = tc.alternatingRowColor {
                        drawCellBackground(bounds: cellBounds, color: altColor, borderWidth: tc.borderWidth, context: &context)
                    }
                }
            }
            // Then render content
            PDF.HTML.renderBlock(view.content, context: &context)
        }

        // Flush any pending inline content
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Get actual row height (max of all cells, minimum single line)
        let actualRowHeight: PDF.UserSpace.Height
        if let tc = context.tableContext {
            actualRowHeight = tc.maxCellHeightInCurrentRow.value > minRowHeight.value
                ? tc.maxCellHeightInCurrentRow
                : minRowHeight
        } else {
            actualRowHeight = minRowHeight
        }

        // If row is taller than minRowHeight, extend backgrounds to full height
        // Then draw all cell borders with correct row height
        if let tc = context.tableContext {
            // Extend backgrounds if needed (draw additional strip below initial background)
            if actualRowHeight.value > minRowHeight.value {
                let extensionHeight = PDF.UserSpace.Height(actualRowHeight.value - minRowHeight.value)
                let extensionY = PDF.UserSpace.Y(rowStartY.value + minRowHeight.value)
                for pending in tc.pendingCellBorders {
                    let cellX = tc.xForColumn(pending.column)
                    let cellWidth = tc.widthForColumns(pending.column, count: pending.colspan)
                    let extensionBounds = PDF.UserSpace.Rectangle(
                        x: cellX,
                        y: extensionY,
                        width: cellWidth,
                        height: extensionHeight
                    )
                    if pending.isHeader, let headerBg = tc.headerBackground {
                        drawCellBackground(bounds: extensionBounds, color: headerBg, borderWidth: tc.borderWidth, context: &context)
                    } else if tc.totalRowsRendered % 2 == 1, let altColor = tc.alternatingRowColor {
                        drawCellBackground(bounds: extensionBounds, color: altColor, borderWidth: tc.borderWidth, context: &context)
                    }
                }
            }

            // Draw borders with full row height
            for pending in tc.pendingCellBorders {
                let cellX = tc.xForColumn(pending.column)
                let cellWidth = tc.widthForColumns(pending.column, count: pending.colspan)
                let cellBounds = PDF.UserSpace.Rectangle(
                    x: cellX,
                    y: rowStartY,
                    width: cellWidth,
                    height: actualRowHeight
                )
                drawCellBorder(bounds: cellBounds, tableCtx: tc, context: &context)
            }
        }

        // Update rowHeights array with actual height
        if var tc = context.tableContext {
            tc.rowHeights.append(actualRowHeight)
            context.tableContext = tc
        }

        // Advance Y position past this row using actual height
        context.pdf.layoutBox.lly = PDF.UserSpace.Y(rowStartY.value + actualRowHeight.value)

        // Increment total rows rendered and reset for next row
        if var tc = context.tableContext {
            tc.totalRowsRendered += 1
            tc.currentColumn = 0
            tc.pendingCellBorders = []
            context.tableContext = tc
        }
    }

    /// Render a table cell (td or th)
    private static func renderTableCell(
        _ view: Self,
        isHeader: Bool,
        context: inout PDF.HTML.Context
    ) {
        guard var tableCtx = context.tableContext else {
            // Fallback: render as inline if not in table context
            PDF.HTML.renderInline(view.content, context: &context)
            return
        }

        // Get colspan/rowspan from HTML attributes (default to 1)
        let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
        let rowspan = context.attributes["rowspan"].flatMap { Int($0) } ?? 1

        // Skip cells occupied by rowspan from previous rows
        tableCtx.advanceToNextAvailableColumn()
        context.tableContext = tableCtx

        // Get current column position (after skipping occupied cells)
        let column = tableCtx.currentColumn

        // MEASUREMENT MODE: Just count columns, don't draw anything
        if tableCtx.measureOnly {
            // Add a placeholder column width (will be recalculated after measurement)
            while tableCtx.columnWidths.count <= column {
                tableCtx.columnWidths.append(PDF.UserSpace.Width(0))
            }
            // Advance column counter
            tableCtx.currentColumn += colspan
            context.tableContext = tableCtx
            return
        }

        // DRAWING MODE: Render the cell
        // Skip if beyond column count
        guard column < tableCtx.columnCount else {
            return
        }

        // Calculate cell bounds using Geometry types
        let cellX = tableCtx.xForColumn(column)
        let cellWidth = tableCtx.widthForColumns(column, count: colspan)

        // Create content bounds with proper padding
        let cellPadding = tableCtx.cellPadding
        let contentX = PDF.UserSpace.X(cellX.value + cellPadding)
        let contentWidth = PDF.UserSpace.Width(cellWidth.value - cellPadding * 2)

        // === PRECISE VERTICAL POSITIONING using font metrics ===
        // Get actual font metrics for the current style
        let font = context.pdf.style.font
        let fontSize = context.pdf.style.fontSize
        let ascender = font.metrics.ascender(atSize: fontSize)
        let descender = font.metrics.descender(atSize: fontSize)  // negative value

        // Content height from font metrics: ascender - descender (descender is negative, so this adds)
        let fontContentHeight = ascender - descender

        // Line height from style (includes leading)
        let lineHeight = context.pdf.style.lineHeightPoints.value

        // Half-leading calculation available if needed for future refinement:
        // halfLeading = max(0, (lineHeight - fontContentHeight) / 2)

        // Available content height within cell
        let cellContentHeight = tableCtx.bounds.height.value - cellPadding * 2

        // For vertical centering (HTML default vertical-align: middle):
        // Position text so the visual center of the text block aligns with cell center
        // Visual center of text = baseline - (ascender - descender) / 2 + ascender
        // Simplified: center the line box within available height
        let verticalCenterOffset = Swift.max(PDF.UserSpace.Unit(0), (cellContentHeight - lineHeight) / PDF.UserSpace.Unit(2))

        // Header cells: add slight top padding compensation (headers often feel tight)
        // This accounts for optical adjustment - bold text appears heavier at top
        let headerCompensation: PDF.UserSpace.Unit = isHeader ? PDF.UserSpace.Unit(1.0) : PDF.UserSpace.Unit(0)

        // Content Y position: cell bottom + padding + centering offset + header compensation
        let contentY = PDF.UserSpace.Y(tableCtx.bounds.lly.value + cellPadding + verticalCenterOffset + headerCompensation)

        // Content height: remaining space for text
        let contentHeight = PDF.UserSpace.Height(cellContentHeight - verticalCenterOffset - headerCompensation)

        // Save layout state and set content bounds
        let savedLayoutBox = context.pdf.layoutBox
        context.pdf.layoutBox = PDF.UserSpace.Rectangle(
            x: contentX,
            y: contentY,
            width: contentWidth,
            height: contentHeight
        )

        // Detect text alignment for border tracking (future: implement right-alignment)
        let textAlignment: Horizontal.Alignment = .leading

        // Track Y before content
        let contentStartY = context.pdf.layoutBox.lly

        // Render cell content
        PDF.HTML.renderInline(view.content, context: &context)

        // Flush any pending inline content
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Calculate actual content height used
        let contentEndY = context.pdf.layoutBox.lly
        let actualContentHeight = contentEndY.value - contentStartY.value
        let cellHeight = PDF.UserSpace.Height(actualContentHeight + tableCtx.cellPadding * 2)

        // Update max cell height for this row
        if var tc = context.tableContext {
            if cellHeight.value > tc.maxCellHeightInCurrentRow.value {
                tc.maxCellHeightInCurrentRow = cellHeight
            }
            // Store pending border info (will be drawn after all cells with correct height)
            // For rowspan > 1, defer to after all rows are rendered
            if rowspan > 1 {
                // Defer this spanning cell - border will be drawn after all rows
                tc.deferredSpanningCells.append(.init(
                    originRow: tc.totalRowsRendered,
                    column: column,
                    colspan: colspan,
                    rowspan: rowspan,
                    isHeader: isHeader,
                    startY: tc.bounds.lly
                ))
            } else {
                // Normal cell - draw border after row completes
                tc.pendingCellBorders.append(.init(
                    column: column,
                    colspan: colspan,
                    rowspan: rowspan,
                    isHeader: isHeader,
                    textAlignment: textAlignment
                ))
            }

            // Capture header cell text for page break repetition
            if isHeader && tc.isCapturingHeader {
                let cellText = extractCellText(from: view.content)
                tc.pendingHeaderCells.append(.init(text: cellText, colspan: colspan))
            }

            // Mark cells as occupied for rowspan > 1
            if rowspan > 1 {
                tc.markSpannedCells(
                    fromRow: tc.totalRowsRendered,
                    column: column,
                    rowspan: rowspan,
                    colspan: colspan
                )
            }

            tc.currentColumn += colspan
            context.tableContext = tc
        }

        // Restore layout state
        context.pdf.layoutBox = savedLayoutBox
    }

    /// Draw cell border
    private static func drawCellBorder(
        bounds: PDF.UserSpace.Rectangle,
        tableCtx: PDF.HTML.Context.Table,
        context: inout PDF.HTML.Context
    ) {
        context.pdf.emitRectangle(
            bounds,
            fill: nil,
            stroke: tableCtx.borderColor,
            strokeWidth: PDF.UserSpace.Width(tableCtx.borderWidth)
        )
    }

    /// Draw cell background (inset by half border width to avoid overlap)
    private static func drawCellBackground(
        bounds: PDF.UserSpace.Rectangle,
        color: PDF.Color,
        borderWidth: PDF.UserSpace.Unit = 0,
        context: inout PDF.HTML.Context
    ) {
        // Inset by half the border width so border covers background edge cleanly
        let inset = borderWidth / PDF.UserSpace.Unit(2)
        let insetBounds = PDF.UserSpace.Rectangle(
            x: PDF.UserSpace.X(bounds.llx.value + inset),
            y: PDF.UserSpace.Y(bounds.lly.value + inset),
            width: PDF.UserSpace.Width(bounds.width.value - inset * PDF.UserSpace.Unit(2)),
            height: PDF.UserSpace.Height(bounds.height.value - inset * PDF.UserSpace.Unit(2))
        )
        context.pdf.emitRectangle(
            insetBounds,
            fill: color,
            stroke: nil
        )
    }

    // MARK: - Header Text Extraction

    /// Extract plain text content from cell for header repetition
    private static func extractCellText<CellContent>(from content: CellContent) -> String {
        // Use Mirror to recursively find string content
        let mirror = Mirror(reflecting: content)

        // Check if it's a String directly
        if let str = content as? String {
            return str
        }

        // Check for HTML.Element or other containers with text
        for child in mirror.children {
            if let text = child.value as? String {
                return text
            }
            // Recursively check nested content (using Any to avoid generic issues)
            let nested = extractCellTextFromAny(child.value)
            if !nested.isEmpty {
                return nested
            }
        }

        // Fallback: use string description if it looks like content
        let description = String(describing: content)
        if !description.contains("HTML.Element") && !description.contains("(") && !description.contains("<") {
            return description
        }

        return ""
    }

    /// Helper to extract text from Any type
    private static func extractCellTextFromAny(_ value: Any) -> String {
        if let str = value as? String {
            return str
        }

        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let text = child.value as? String {
                return text
            }
            let nested = extractCellTextFromAny(child.value)
            if !nested.isEmpty {
                return nested
            }
        }

        return ""
    }

    // MARK: - Header Row Repetition

    /// Render the stored header row (called after page break)
    private static func renderRepeatedHeader(context: inout PDF.HTML.Context) {
        guard var tableCtx = context.tableContext,
              let headerCells = tableCtx.headerCells,
              !headerCells.isEmpty else {
            return
        }

        // Reset for header row rendering
        tableCtx.currentColumn = 0
        tableCtx.currentRow = 0
        tableCtx.pendingCellBorders = []
        tableCtx.maxCellHeightInCurrentRow = PDF.UserSpace.Height(0)

        // Update bounds to current layout position
        tableCtx.bounds = PDF.UserSpace.Rectangle(
            x: tableCtx.bounds.llx,
            y: context.pdf.layoutBox.lly,
            width: tableCtx.bounds.width,
            height: tableCtx.headerRowHeight
        )
        context.tableContext = tableCtx

        // Minimum row height from stored header height
        let minRowHeight = tableCtx.headerRowHeight.value > 0
            ? tableCtx.headerRowHeight
            : PDF.UserSpace.Height(context.pdf.style.lineHeightPoints.value + tableCtx.cellPadding * 2)

        // PRE-DRAW: Draw header backgrounds before content
        var cellColumn = 0
        for headerCell in headerCells {
            let cellX = tableCtx.xForColumn(cellColumn)
            let cellWidth = tableCtx.widthForColumns(cellColumn, count: headerCell.colspan)
            let cellBounds = PDF.UserSpace.Rectangle(
                x: cellX,
                y: tableCtx.bounds.lly,
                width: cellWidth,
                height: minRowHeight
            )

            // Draw header background
            if let headerBg = tableCtx.headerBackground {
                drawCellBackground(bounds: cellBounds, color: headerBg, borderWidth: tableCtx.borderWidth, context: &context)
            }

            cellColumn += headerCell.colspan
        }

        // RENDER: Draw header cell content
        cellColumn = 0
        for headerCell in headerCells {
            let cellX = tableCtx.xForColumn(cellColumn)
            let cellWidth = tableCtx.widthForColumns(cellColumn, count: headerCell.colspan)

            // Calculate content bounds with padding
            let cellPadding = tableCtx.cellPadding
            let contentX = PDF.UserSpace.X(cellX.value + cellPadding)
            let contentWidth = PDF.UserSpace.Width(cellWidth.value - cellPadding * 2)

            // Vertical centering
            let lineHeight = context.pdf.style.lineHeightPoints.value
            let cellContentHeight = minRowHeight.value - cellPadding * 2
            let verticalCenterOffset = Swift.max(PDF.UserSpace.Unit(0), (cellContentHeight - lineHeight) / PDF.UserSpace.Unit(2))
            let headerCompensation: PDF.UserSpace.Unit = 1.0
            let contentY = PDF.UserSpace.Y(tableCtx.bounds.lly.value + cellPadding + verticalCenterOffset + headerCompensation)

            // Save state, render text, restore
            let savedLayoutBox = context.pdf.layoutBox
            let savedStyle = context.pdf.style

            // Apply bold for headers
            context.pdf.style.font = context.pdf.style.font.bold

            context.pdf.layoutBox = PDF.UserSpace.Rectangle(
                x: contentX,
                y: contentY,
                width: contentWidth,
                height: PDF.UserSpace.Height(cellContentHeight)
            )

            // Render header text using TextRun
            let run = PDF.Context.TextRun(
                text: headerCell.text,
                font: context.pdf.style.font,
                fontSize: context.pdf.style.fontSize,
                color: context.pdf.style.color,
                textDecoration: context.pdf.style.textMarkup,
                verticalOffset: context.pdf.style.verticalOffset
            )
            context.pdf.append(inline: run)
            context.pdf.flushInlineRuns()

            context.pdf.style = savedStyle
            context.pdf.layoutBox = savedLayoutBox

            cellColumn += headerCell.colspan
        }

        // DRAW BORDERS: After content with correct height
        cellColumn = 0
        for headerCell in headerCells {
            let cellX = tableCtx.xForColumn(cellColumn)
            let cellWidth = tableCtx.widthForColumns(cellColumn, count: headerCell.colspan)
            let cellBounds = PDF.UserSpace.Rectangle(
                x: cellX,
                y: tableCtx.bounds.lly,
                width: cellWidth,
                height: minRowHeight
            )

            drawCellBorder(bounds: cellBounds, tableCtx: tableCtx, context: &context)
            cellColumn += headerCell.colspan
        }

        // Advance Y position past header row
        context.pdf.layoutBox = PDF.UserSpace.Rectangle(
            x: context.pdf.layoutBox.llx,
            y: PDF.UserSpace.Y(context.pdf.layoutBox.lly.value + minRowHeight.value),
            width: context.pdf.layoutBox.width,
            height: PDF.UserSpace.Height(context.pdf.layoutBox.height.value - minRowHeight.value)
        )
    }

}
