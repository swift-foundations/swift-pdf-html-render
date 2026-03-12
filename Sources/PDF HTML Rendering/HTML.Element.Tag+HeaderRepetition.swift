// HTML.Element.Tag+HeaderRepetition.swift
// Table header repetition after page breaks

import HTML_Renderable
import PDF_Rendering

extension HTML.Element.Tag {
    /// Render the stored header row (called after page break)
    static func renderRepeatedHeader(context: inout PDF.HTML.Context) {
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
