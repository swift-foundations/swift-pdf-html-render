// HTML.Element.Tag+TableCell.swift
// Table cell rendering (td and th)

import HTML_Renderable
import Layout_Primitives
import PDF_Rendering

extension HTML.Element.Tag {
    /// Render a table cell (td or th)
    static func renderTableCell(
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

        // Text alignment comes from CSS via Style.Modifier (e.g., .css.textAlign(.right))
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
            // Affine subtraction: Y - Y = Dy, then convert to Height and take absolute value
            actualContentHeight = height(contentEndY - contentStartY).magnitude

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
