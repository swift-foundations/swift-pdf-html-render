// HTML.Element+PDF.HTML.View.swift
// HTML.Element rendering using runtime tag metadata

import CSS_Standard
import Dimension_Primitives
import HTML_Renderable
import Layout_Primitives
import Dictionary_Primitives
import PDF_Rendering
import WHATWG_HTML

// MARK: - Text Extraction Protocol (Performance Optimization)

/// Protocol for types that can efficiently extract text for PDF table headers.
/// Conforming to this protocol avoids expensive Mirror reflection.
public protocol PDFTextExtractable {
    /// The extracted text content for PDF rendering
    var pdfExtractedText: String { get }
}

extension String: PDFTextExtractable {
    @inlinable
    public var pdfExtractedText: String { self }
}

extension HTML.Element.Tag: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        renderTag(
            view,
            context: &context,
            renderBlock: { content, ctx in PDF.HTML.renderBlock(content, context: &ctx) },
            renderInline: { content, ctx in PDF.HTML.renderInline(content, context: &ctx) }
        )
    }
}

// MARK: - Shared Helpers (no Content constraint needed)
// These helper methods are extracted to an unconstrained extension so they can be
// called from both the static dispatch path (Content: PDF.HTML.View) and the
// dynamic dispatch path (Content: HTML.View).

extension HTML.Element.Tag {
    /// Render void element (br, hr, etc.)
    fileprivate static func renderVoidElement(
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

    /// Check if tag is a list container
    fileprivate static func isListContainer(_ tagName: String) -> Bool {
        tagName == "ol" || tagName == "ul"
    }

    /// Get list type for a list container tag
    fileprivate static func listType(for tagName: String) -> PDF.Context.ListType? {
        switch tagName {
        case "ol": return .ordered(startNumber: 1)
        case "ul": return .unordered
        default: return nil
        }
    }

    /// Apply tag-specific styling based on tag name
    fileprivate static func applyTagStyle(_ tagName: String, context: inout PDF.HTML.Context) {
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
            context.pdf.style.textMarkup = .strikeOut
        case "u", "ins":
            context.pdf.style.textMarkup = .underline
        case "mark":
            context.pdf.style.textMarkup = .highlight(.rgb(red: 1.0, green: 1.0, blue: 0.0))

        // Sub/superscript
        // WebKit: font-size ~0.83em, vertical-align: sub/super
        case "sub":
            let currentSize = context.pdf.style.fontSize
            context.pdf.style.fontSize = currentSize * context.configuration.typography.subscriptScale
            // Subscript drops below baseline
            context.pdf.style.verticalOffset = context.pdf.style.verticalOffset - (currentSize * context.configuration.typography.subscriptOffset).height
        case "sup":
            let currentSize = context.pdf.style.fontSize
            context.pdf.style.fontSize = currentSize * context.configuration.typography.superscriptScale
            // Superscript rises above baseline
            context.pdf.style.verticalOffset = context.pdf.style.verticalOffset + (currentSize * context.configuration.typography.superscriptOffset).height

        // Small - WebKit default is smaller
        case "small":
            context.pdf.style.fontSize = context.pdf.style.fontSize * context.configuration.typography.smallScale

        // Links
        case "a":
            context.pdf.style.color = .blue
            context.pdf.style.textMarkup = .underline

        // Block indentation
        // WebKit default margin-left for blockquote is 40px = 30pt (at 72/96 conversion)
        case "blockquote", "dd":
            let indent = context.configuration.indent.blockquote
            context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + indent
        case "figure":
            let margin = context.configuration.indent.figure
            context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + margin
            context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - margin

        // Citation, definition, and variable (all italic in WebKit)
        case "cite", "dfn", "var":
            context.pdf.style.font = context.pdf.style.font.italic

        default:
            break
        }
    }

    /// Get block margins for a tag name
    fileprivate static func blockMargins(
        for tagName: String,
        configuration: PDF.HTML.Configuration
    ) -> (top: LengthPercentage, bottom: LengthPercentage)? {
        switch tagName {
        case "p":
            return (.length(.em(1.0)), .length(.em(1.0)))
        case "h1", "h2", "h3", "h4", "h5", "h6":
            let margin = configuration.headingMarginEm(for: tagName).value
            return (.length(.em(margin)), .length(.em(margin)))
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

    /// Draw cell border (only left and top edges to avoid double borders)
    ///
    /// Uses border-collapse approach: each cell draws its left and top borders.
    /// The table's right and bottom edges are drawn once at the end.
    fileprivate static func drawCellBorder(
        bounds: PDF.UserSpace.Rectangle,
        tableCtx: PDF.HTML.Context.Table,
        context: inout PDF.HTML.Context
    ) {
        let color = tableCtx.borderColor
        let width = tableCtx.borderWidth.width

        // Draw left edge (from lower-left to upper-left)
        context.pdf.emitLine(
            from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
            to: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.ury),
            color: color,
            width: width
        )

        // Draw top edge (from lower-left to lower-right)
        context.pdf.emitLine(
            from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
            to: PDF.UserSpace.Coordinate(x: bounds.urx, y: bounds.lly),
            color: color,
            width: width
        )
    }

    /// Draw right and bottom borders for a table fragment (per-page section)
    ///
    /// For multi-page tables, this is called:
    /// 1. Before each page break (to close the fragment on the current page)
    /// 2. At the end of the table (to close the final fragment)
    fileprivate static func drawFragmentRightAndBottomBorders(
        tableCtx: PDF.HTML.Context.Table,
        fragmentStartY: PDF.UserSpace.Y,
        fragmentEndY: PDF.UserSpace.Y,
        context: inout PDF.HTML.Context
    ) {
        guard tableCtx.columnWidths.count > 0 else { return }

        let color = tableCtx.borderColor
        let width = tableCtx.borderWidth.width
        let tableBounds = tableCtx.bounds

        // Draw right edge (from fragment top to fragment bottom)
        context.pdf.emitLine(
            from: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentStartY),
            to: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentEndY),
            color: color,
            width: width
        )

        // Draw bottom edge (from table left to table right)
        context.pdf.emitLine(
            from: PDF.UserSpace.Coordinate(x: tableBounds.llx, y: fragmentEndY),
            to: PDF.UserSpace.Coordinate(x: tableBounds.urx, y: fragmentEndY),
            color: color,
            width: width
        )
    }

    /// Draw the table's right and bottom borders (completing the border-collapse grid)
    /// Convenience wrapper that uses the current fragment tracking properties.
    fileprivate static func drawTableRightAndBottomBorders(
        tableCtx: PDF.HTML.Context.Table,
        context: inout PDF.HTML.Context
    ) {
        drawFragmentRightAndBottomBorders(
            tableCtx: tableCtx,
            fragmentStartY: tableCtx.currentFragmentStartY,
            fragmentEndY: tableCtx.currentFragmentEndY,
            context: &context
        )
    }

    /// Draw cell background (inset by half border width to avoid overlap)
    fileprivate static func drawCellBackground(
        bounds: PDF.UserSpace.Rectangle,
        color: PDF.Color,
        borderWidth: PDF.UserSpace.Size<1> = 0,
        context: inout PDF.HTML.Context
    ) {
        // Inset by half the border width so border covers background edge cleanly
        let insetX = borderWidth.width / 2
        let insetY = borderWidth.height / 2
        context.pdf.emitRectangle(
            bounds.insetBy(dx: insetX, dy: insetY),
            fill: color,
            stroke: nil
        )
    }

    // MARK: - Heading Level Detection

    /// Get heading level for tag name (nil if not a heading)
    fileprivate static func headingLevel(for tagName: String) -> Int? {
        switch tagName {
        case "h1": return 1
        case "h2": return 2
        case "h3": return 3
        case "h4": return 4
        case "h5": return 5
        case "h6": return 6
        default: return nil
        }
    }

    // MARK: - Header Text Extraction

    /// Extract plain text content from cell for header repetition
    fileprivate static func extractCellText<CellContent>(from content: CellContent) -> String {
        // Fast path: Check PDFTextExtractable protocol (avoids Mirror reflection)
        if let extractable = content as? PDFTextExtractable {
            return extractable.pdfExtractedText
        }

        // Fallback: Use Mirror to recursively find string content
        let mirror = Mirror(reflecting: content)

        // Check for HTML.Element or other containers with text
        for child in mirror.children {
            // Check protocol first for child values
            if let extractable = child.value as? PDFTextExtractable {
                return extractable.pdfExtractedText
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
    fileprivate static func extractCellTextFromAny(_ value: Any) -> String {
        // Fast path: Check PDFTextExtractable protocol (avoids Mirror reflection)
        if let extractable = value as? PDFTextExtractable {
            return extractable.pdfExtractedText
        }

        // Fallback to Mirror
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let extractable = child.value as? PDFTextExtractable {
                return extractable.pdfExtractedText
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
    fileprivate static func renderRepeatedHeader(context: inout PDF.HTML.Context) {
        guard var tableCtx = context.table,
              let headerCells = tableCtx.header.cells,
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
            height: tableCtx.header.rowHeight
        )
        context.table = tableCtx

        // Minimum row height from stored header height
        let minRowHeight = tableCtx.header.rowHeight > .init(0)
            ? tableCtx.header.rowHeight
            : context.pdf.style.line.height + tableCtx.cell.padding.height * 2

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
            let cellPadding = tableCtx.cell.padding
            let contentX = cellX + cellPadding.width
            let contentWidth = cellWidth - cellPadding.width * 2

            // Vertical centering
            let lineHeight = context.pdf.style.line.height
            let cellContentHeight = minRowHeight - cellPadding.height * 2
            let verticalCenterOffset = Swift.max(PDF.UserSpace.Height(0), (cellContentHeight - lineHeight) / 2)
            let headerCompensation: PDF.UserSpace.Height = .init(1.0)
            let contentY = tableCtx.bounds.lly + cellPadding.height + verticalCenterOffset + headerCompensation

            // Save state, render text, restore
            let savedLayoutBox = context.pdf.layoutBox
            let savedStyle = context.pdf.style

            // Apply bold for headers
            context.pdf.style.font = context.pdf.style.font.bold

            context.pdf.layoutBox = PDF.UserSpace.Rectangle(
                x: contentX,
                y: contentY,
                width: contentWidth,
                height: cellContentHeight
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
        let newY = context.pdf.layoutBox.lly + minRowHeight
        context.pdf.layoutBox = PDF.UserSpace.Rectangle(
            x: context.pdf.layoutBox.llx,
            y: newY,
            width: context.pdf.layoutBox.width,
            height: context.pdf.layoutBox.height - minRowHeight
        )

        // Update fragment end position to include the repeated header
        context.with(\.table) { tc in
            tc.currentFragmentEndY = newY
        }
    }
}

// MARK: - Unified Rendering (parameterized on block/inline dispatch)

extension HTML.Element.Tag {
    /// Unified tag rendering, parameterized on how child content is dispatched.
    ///
    /// Both the static (`PDF.HTML.View`) and dynamic (`HTML.View`) entry points
    /// delegate here, supplying the appropriate `renderBlock`/`renderInline` closures.
    fileprivate static func renderTag(
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
        let savedLinkURL = context.currentLinkURL
        let savedInternalLinkId = context.currentInternalLinkId

        defer {
            context.pdf.style = savedStyle
            context.pdf.layoutBox.llx = savedLLX
            context.pdf.layoutBox.urx = savedURX
            context.pdf.preserveWhitespace = savedPreserveWhitespace
            context.currentLinkURL = savedLinkURL
            context.currentInternalLinkId = savedInternalLinkId
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
                    context.currentInternalLinkId = String(href.dropFirst())
                } else {
                    // External link - store the full URL
                    context.currentLinkURL = href
                }
            }
        }

        // Collect named destination for elements with id attribute (for internal links)
        if let elementId = context.attributes["id"], !elementId.isEmpty {
            // Use completedPages.count + 1 for correct 1-indexed page number
            // pages.count includes current page if non-empty, which would overcount
            let pageNumber = context.pdf.completedPages.count + 1
            let yPosition = context.pdf.layoutBox.lly
            context.namedDestinations[elementId] = PDF.HTML.Context.DestinationInfo(
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
    fileprivate static func renderWithFlow(
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

                context.collectedHeadings.append(PDF.HTML.Context.HeadingEntry(
                    level: heading.level,
                    text: heading.text,
                    pageNumber: pageNumber,
                    yPosition: yPosition
                ))

                // For H1-H3, update section tracking for headers/footers
                if heading.level <= 3 {
                    context.currentSectionTitle = heading.text
                    if context.pageSectionTitles[pageNumber] == nil {
                        context.pageSectionTitles[pageNumber] = heading.text
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

    // MARK: - Table Rendering (Unified)

    /// Render a table element
    fileprivate static func renderTable(
        _ view: Self,
        context: inout PDF.HTML.Context,
        renderBlock: (Content?, inout PDF.HTML.Context) -> Void
    ) {
        // Save current context state
        let savedTableContext = context.table
        let tableStartY = context.pdf.layoutBox.lly

        // Get available width and configuration
        let availableWidth = context.pdf.layoutBox.width
        let cellPadding = context.configuration.table.cell.padding

        // Start with empty columns - will be populated dynamically on first row
        let columnWidths: [PDF.UserSpace.Width] = []

        // Estimate row height
        let defaultRowHeight = context.pdf.style.line.height + cellPadding.height * 2
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
        context.table = PDF.HTML.Context.Table(
            bounds: tableBounds,
            columnWidths: columnWidths,
            rowHeights: rowHeights,
            cellPadding: cellPadding,
            borderColor: context.configuration.table.border.color,
            borderWidth: context.configuration.table.border.width,
            headerBackground: context.configuration.table.headerBackground,
            alternatingRowColor: context.configuration.table.alternatingRowColor
        )
        // Track total rows for Y advancement
        context.table?.totalRowsRendered = 0
        // Note: tableStartY will be set when first row renders (not here, to avoid capturing
        // the position before the actual table content starts)

        // Reset margin collapsing within table
        context.resetMarginCollapsing()

        // Render table content
        renderBlock(view.content, &context)

        // Draw deferred spanning cells (rowspan > 1)
        // These cells need content + borders that span multiple rows
        if let tc = context.table {
            for deferred in tc.deferredSpanningCells {
                // Calculate total height across all spanned rows
                let startRow = deferred.origin.row
                let endRow = startRow + deferred.span.row.span
                var totalHeight: PDF.UserSpace.Height = .init(0)
                for rowIndex in startRow..<min(endRow, tc.rowHeights.count) {
                    totalHeight += tc.rowHeights[rowIndex]
                }

                // Use stored cell bounds for consistency with normal cells
                let cellBounds = PDF.UserSpace.Rectangle(
                    x: deferred.cell.x,
                    y: deferred.cell.y,
                    width: deferred.cell.width,
                    height: totalHeight
                )

                // Draw background for spanning cell
                if deferred.isHeader, let headerBg = tc.headerBackground {
                    drawCellBackground(bounds: cellBounds, color: headerBg, borderWidth: tc.borderWidth, context: &context)
                }

                // Draw border for spanning cell
                drawCellBorder(bounds: cellBounds, tableCtx: tc, context: &context)

                // Render content with vertical centering
                let cellContentHeight = totalHeight - tc.cell.padding.height * 2
                let lineHeight = deferred.savedStyle.line.height
                let verticalCenterOffset = max(PDF.UserSpace.Height(0), (cellContentHeight - lineHeight) / 2)

                // Calculate content position with vertical centering
                let contentY = deferred.cell.y + tc.cell.padding.height + verticalCenterOffset

                // Save context state
                let savedLayoutBox = context.pdf.layoutBox
                let savedStyle = context.pdf.style

                // Apply deferred style with alignment
                context.pdf.style = deferred.savedStyle
                context.pdf.style.textAlign = deferred.textAlignment
                context.pdf.layoutBox = PDF.UserSpace.Rectangle(
                    x: deferred.content.x,
                    y: contentY,
                    width: deferred.content.width,
                    height: cellContentHeight - verticalCenterOffset
                )

                // Render the deferred text content
                let runs = PDF.Context.TextRun.runsWithSymbolSupport(
                    text: deferred.text,
                    font: deferred.savedStyle.font,
                    fontSize: deferred.savedStyle.fontSize,
                    color: deferred.savedStyle.color,
                    textDecoration: deferred.savedStyle.textMarkup,
                    verticalOffset: deferred.savedStyle.verticalOffset
                )
                for run in runs {
                    context.pdf.append(inline: run)
                }
                context.pdf.flushInlineRuns()

                // Restore context state
                context.pdf.style = savedStyle
                context.pdf.layoutBox = savedLayoutBox
            }

            // Draw the table's right and bottom borders (border-collapse)
            drawTableRightAndBottomBorders(tableCtx: tc, context: &context)
        }

        // Advance past the table - use current layoutBox position which was updated by rows
        // Add a small gap after the table
        context.pdf.advance((context.configuration.defaultFontSize * context.configuration.horizontalGapEm).height)

        // Restore context
        context.table = savedTableContext
    }

    /// Render a table row
    fileprivate static func renderTableRow(
        _ view: Self,
        context: inout PDF.HTML.Context,
        renderBlock: (Content?, inout PDF.HTML.Context) -> Void
    ) {
        guard var tableCtx = context.table else {
            // Fallback: render as block if not in table context
            renderBlock(view.content, &context)
            return
        }

        // Reset for this row
        tableCtx.currentColumn = 0
        tableCtx.maxCellHeightInCurrentRow = PDF.UserSpace.Height(0)
        tableCtx.pendingCellBorders = []

        // === CALCULATE ROW-WIDE BASELINE METRICS ===
        // To ensure consistent baseline alignment across all cells (header and data),
        // we compute max ascent/descent for BOTH regular and bold font variants.
        // This fixes baseline drift between bold headers and regular data cells.
        let fontSize = context.pdf.style.fontSize
        let regularFont = context.pdf.style.font
        let boldFont = regularFont.bold

        let regularAscent = regularFont.metrics.ascender(atSize: fontSize)
        let regularDescent = abs(regularFont.metrics.descender(atSize: fontSize))
        let boldAscent = boldFont.metrics.ascender(atSize: fontSize)
        let boldDescent = abs(boldFont.metrics.descender(atSize: fontSize))

        tableCtx.currentRowMaxAscent = max(regularAscent, boldAscent)
        tableCtx.currentRowMaxDescent = max(regularDescent, boldDescent)

        // Calculate minimum row height (single line)
        let minRowHeight = context.pdf.style.line.height + tableCtx.cell.padding.height * 2

        // For page break check: account for header repetition if headers exist
        let headerHeight = tableCtx.header.hasHeader ? tableCtx.header.rowHeight : PDF.UserSpace.Height(0)
        let totalNeeded = minRowHeight + headerHeight

        // BEFORE page break: if we would exceed the page AND have already rendered rows,
        // draw the fragment's right and bottom borders to close this page's fragment.
        // We must do this BEFORE checkPageBreak since we can't draw on previous pages after.
        let willPageBreak = context.pdf.wouldExceedPage(adding: totalNeeded)
        if willPageBreak && tableCtx.columnsInitialized && tableCtx.totalRowsRendered > 0 {
            // Draw fragment borders for the portion on this page
            drawFragmentRightAndBottomBorders(
                tableCtx: tableCtx,
                fragmentStartY: tableCtx.currentFragmentStartY,
                fragmentEndY: tableCtx.currentFragmentEndY,
                context: &context
            )
        }

        // Check if row (plus header if needed) fits on current page
        let didPageBreak = context.pdf.checkPageBreak(needing: totalNeeded)

        // After page break, reset fragment tracking BEFORE repeating headers
        // so the fragment includes the repeated header row
        if didPageBreak && tableCtx.columnsInitialized {
            // The new fragment starts at the top of the new page
            tableCtx.currentFragmentStartY = context.pdf.layoutBox.lly
            tableCtx.currentFragmentEndY = context.pdf.layoutBox.lly
            context.table = tableCtx
        }

        // If page break occurred and we have stored headers, repeat them
        if didPageBreak && tableCtx.header.hasHeader && tableCtx.columnsInitialized {
            renderRepeatedHeader(context: &context)
            // Refresh tableCtx after header rendering
            if let tc = context.table {
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

        context.table = tableCtx

        // Save the current Y position for row start
        let rowStartY = context.pdf.layoutBox.lly

        // Update table bounds Y to current row position for cell rendering
        // This ensures rowspan cells capture the correct Y position
        tableCtx.bounds.lly = rowStartY
        context.table = tableCtx

        // Track table start position from first row (not from <table> entry)
        // This ensures borders start at the actual first row, not above it
        if tableCtx.totalRowsRendered == 0 {
            context.with(\.table) { tc in
                tc.tableStartY = rowStartY
                // Initialize fragment tracking for the first page
                tc.currentFragmentStartY = rowStartY
                tc.currentFragmentEndY = rowStartY
                tableCtx = tc
            }
        }

        // FIRST ROW: Two-pass rendering for column counting
        if !tableCtx.columnsInitialized {
            // Pass 1: Measurement - count columns only
            context.with(\.table) { tc in
                tc.measureOnly = true
                tc.currentColumn = 0
            }
            renderBlock(view.content, &context)

            // After measurement, set up correct column widths
            context.with(\.table) { tc in
                tc.measureOnly = false
                tc.columnsInitialized = true
                let columnCount = tc.columnWidths.count
                if columnCount > 0 {
                    let equalWidth = tc.bounds.width / Scale(Double(columnCount))
                    tc.columnWidths = Array(repeating: equalWidth, count: columnCount)
                    // Pre-allocate span grid to avoid dynamic growth (64 rows covers most tables)
                    tc.spans.preallocate(rows: 64, columns: columnCount)
                }
                // Reset for drawing pass
                tc.currentColumn = 0
                tc.maxCellHeightInCurrentRow = PDF.UserSpace.Height(0)
                tc.pendingCellBorders = []
            }

            // Pass 2: Pre-draw backgrounds (using min height - will be redrawn if content is taller)
            if let tc = context.table {
                for col in 0..<tc.columnCount {
                    // Skip columns occupied by rowspan from previous rows
                    if tc.spans.isOccupied(row: tc.totalRowsRendered, column: col) {
                        continue
                    }
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
            renderBlock(view.content, &context)
        } else {
            // Subsequent rows: Draw backgrounds first, then content
            if let tc = context.table {
                for col in 0..<tc.columnCount {
                    // Skip columns occupied by rowspan from previous rows
                    if tc.spans.isOccupied(row: tc.totalRowsRendered, column: col) {
                        continue
                    }
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
            renderBlock(view.content, &context)
        }

        // Flush any pending inline content
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Get actual row height (max of all cells, minimum single line)
        let actualRowHeight: PDF.UserSpace.Height
        if let tc = context.table {
            actualRowHeight = tc.maxCellHeightInCurrentRow > minRowHeight
                ? tc.maxCellHeightInCurrentRow
                : minRowHeight
        } else {
            actualRowHeight = minRowHeight
        }

        // If row is taller than minRowHeight, extend backgrounds to full height
        // Then draw all cell borders with correct row height
        if let tc = context.table {
            // Extend backgrounds if needed (draw additional strip below initial background)
            if actualRowHeight > minRowHeight {
                let extensionHeight = actualRowHeight - minRowHeight
                let extensionY = rowStartY + minRowHeight
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
        context.with(\.table) { tc in
            tc.rowHeights.append(actualRowHeight)
        }

        // Advance Y position past this row using actual height
        let newY = rowStartY + actualRowHeight
        context.pdf.layoutBox.lly = newY

        // Track table end position (updated after each row for accurate border drawing)
        context.with(\.table) { tc in
            tc.tableEndY = newY
            // Also update current fragment end for per-page border drawing
            tc.currentFragmentEndY = newY
        }

        // Increment total rows rendered and reset for next row
        context.with(\.table) { tc in
            tc.totalRowsRendered += 1
            tc.currentColumn = 0
            tc.pendingCellBorders = []
        }
    }

    /// Render a table cell (td or th)
    fileprivate static func renderTableCell(
        _ view: Self,
        isHeader: Bool,
        context: inout PDF.HTML.Context,
        renderInline: (Content?, inout PDF.HTML.Context) -> Void
    ) {
        guard var tableCtx = context.table else {
            // Fallback: render as inline if not in table context
            renderInline(view.content, &context)
            return
        }

        // Get colspan/rowspan from HTML attributes (default to 1)
        let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
        let rowspan = context.attributes["rowspan"].flatMap { Int($0) } ?? 1

        // Skip cells occupied by rowspan from previous rows
        tableCtx.advanceToNextAvailableColumn()
        context.table = tableCtx  // Sync after column advance

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
            context.table = tableCtx
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
        let cellPadding = tableCtx.cell.padding
        let contentX = cellX + cellPadding.width
        let contentWidth = cellWidth - cellPadding.width * 2

        // === PRECISE VERTICAL POSITIONING using ROW-WIDE font metrics ===
        // Use row-wide max ascent/descent to ensure consistent baseline across all cells
        // This fixes bold/regular baseline drift in mixed header/data rows
        let rowMaxAscent = tableCtx.currentRowMaxAscent
        let rowMaxDescent = tableCtx.currentRowMaxDescent

        // Content height from row-wide font metrics
        let fontContentHeight = rowMaxAscent + rowMaxDescent

        // Line height from style (includes leading)
        let lineHeight = context.pdf.style.line.height

        // Use the larger of font content height or line height for consistent spacing
        let effectiveLineHeight = max(fontContentHeight, lineHeight)

        // Available content height within cell
        let cellContentHeight = tableCtx.bounds.height - cellPadding.height * 2

        // For vertical centering (HTML default vertical-align: middle):
        // Position text so the visual center of the text block aligns with cell center
        let verticalCenterOffset = Swift.max(PDF.UserSpace.Height(0), (cellContentHeight - effectiveLineHeight) / 2)

        // Header cells: add slight top padding compensation (headers often feel tight)
        // This accounts for optical adjustment - bold text appears heavier at top
        let headerCompensation: PDF.UserSpace.Height = isHeader ? .init(1.0) : .init(0)

        // Content Y position: cell bottom + padding + centering offset + header compensation
        let contentY = tableCtx.bounds.lly + cellPadding.height + verticalCenterOffset + headerCompensation

        // Content height: remaining space for text
        let contentHeight = cellContentHeight - verticalCenterOffset - headerCompensation

        // Save layout state and set content bounds
        let savedLayoutBox = context.pdf.layoutBox
        context.pdf.layoutBox = PDF.UserSpace.Rectangle(
            x: contentX,
            y: contentY,
            width: contentWidth,
            height: contentHeight
        )

        // Text alignment comes from CSS via StyleModifier (e.g., .css.textAlign(.right))
        // The context.pdf.style.textAlign is already set by CSS processing
        let textAlignment = context.pdf.style.textAlign

        // Track Y before content
        let contentStartY = context.pdf.layoutBox.lly

        // For rowspan > 1 cells: defer content rendering for vertical centering
        // For normal cells: render content immediately
        let actualContentHeight: PDF.UserSpace.Height
        if rowspan > 1 {
            // DEFER content rendering - extract text and save for later
            let contentText = extractCellText(from: view.content)

            // Use single line height as placeholder for row height calculation
            actualContentHeight = context.pdf.style.line.height

            // Capture style and cell Y before entering closure for consistency
            // All cell bounds (x, y, width) should come from the same source (tableCtx)
            let savedStyle = context.pdf.style
            let cellY = tableCtx.bounds.lly

            context.with(\.table) { tc in
                // Defer this spanning cell - content + border will be drawn after all rows
                tc.deferredSpanningCells.append(.init(
                    origin: .init(row: tc.totalRowsRendered),
                    column: column,
                    span: .init(
                        col: .init(span: colspan),
                        row: .init(span: rowspan)
                    ),
                    isHeader: isHeader,
                    cell: .init(x: cellX, y: cellY, width: cellWidth),
                    content: .init(x: contentX, width: contentWidth),
                    savedStyle: savedStyle,
                    text: contentText,
                    textAlignment: textAlignment
                ))

                // Mark cells as occupied for rowspan > 1
                tc.spans.mark(
                    fromRow: tc.totalRowsRendered,
                    column: column,
                    rowspan: rowspan,
                    colspan: colspan,
                    columnCount: tc.columnCount
                )

                // Capture header cell text for page break repetition
                if isHeader && tc.header.isCapturing {
                    tc.header.addCell(.init(text: contentText, colspan: colspan))
                }

                tc.currentColumn += colspan
            }
        } else {
            // NORMAL cell - render content immediately
            renderInline(view.content, &context)

            // Flush any pending inline content
            if context.pdf.hasInlineRuns {
                context.pdf.flushInlineRuns()
            }

            // Calculate actual content height used
            let contentEndY = context.pdf.layoutBox.lly
            // Convert Dy (displacement) to Height (extent) - in PDF Y goes up, so content going down gives negative Dy
            actualContentHeight = PDF.UserSpace.Height(abs(contentEndY.rawValue - contentStartY.rawValue))

            // Update max cell height and store pending border
            context.with(\.table) { tc in
                // Normal cell - draw border after row completes
                tc.pendingCellBorders.append(.init(
                    column: column,
                    colspan: colspan,
                    rowspan: rowspan,
                    isHeader: isHeader,
                    textAlignment: textAlignment
                ))

                // Capture header cell text for page break repetition
                if isHeader && tc.header.isCapturing {
                    let cellText = extractCellText(from: view.content)
                    tc.header.addCell(.init(text: cellText, colspan: colspan))
                }

                tc.currentColumn += colspan
            }
        }

        // Calculate cell height (for row height tracking)
        let cellHeight = actualContentHeight + tableCtx.cell.padding.height * 2

        // Update max cell height for this row
        context.with(\.table) { tc in
            if cellHeight > tc.maxCellHeightInCurrentRow {
                tc.maxCellHeightInCurrentRow = cellHeight
            }
        }

        // Restore layout state
        context.pdf.layoutBox = savedLayoutBox
    }
}

// MARK: - Dynamic Dispatch Support for HTML.Element.Tag

/// Conformance to `_HTMLElementContent` enables runtime dispatch for `HTML.Element.Tag<Content>`
/// when `Content` doesn't statically conform to `PDF.HTML.View` but is an `HTML.View`.
///
/// This mirrors the static dispatch `_render` method but uses dynamic dispatch helpers
/// (`renderBlockDynamic`, `renderInlineDynamic`) for content rendering.
extension HTML.Element.Tag: _HTMLElementContent where Content: HTML.View {
    public func _renderElementDynamically(context: inout PDF.HTML.Context) {
        Self.renderTag(
            self,
            context: &context,
            renderBlock: { content, ctx in PDF.HTML.renderBlockDynamic(content, context: &ctx) },
            renderInline: { content, ctx in PDF.HTML.renderInlineDynamic(content, context: &ctx) }
        )
    }
}

