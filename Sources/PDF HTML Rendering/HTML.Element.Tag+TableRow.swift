// HTML.Element.Tag+TableRow.swift
// Table row rendering with page break handling and header repetition

import HTML_Renderable
import PDF_Rendering

extension HTML.Element.Tag {
    /// Render a table row
    static func renderTableRow(
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
}
