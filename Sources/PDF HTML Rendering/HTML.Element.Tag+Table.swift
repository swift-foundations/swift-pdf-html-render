// HTML.Element.Tag+Table.swift
// Table element rendering

import HTML_Renderable
import PDF_Rendering

extension HTML.Element.Tag {
    /// Render a table element
    static func renderTable(
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
}
