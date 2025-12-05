// HTML.Element+PDF.HTML.View.swift
// HTML.Element rendering using WHATWG_HTML.Element.flow

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension HTML.Element: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Check if this is a void element (br, hr, etc.) - no content
        if let voidRenderer = Tag.self as? any PDF.HTML.VoidElementRenderer.Type {
            voidRenderer.render(into: &buffer, context: &context)
            return
        }

        // Check if this is a list container (ul, ol) - needs special handling
        if let listContainer = Tag.self as? any PDF.HTML.ListContainer.Type {
            renderListContainer(view, listContainer: listContainer, into: &buffer, context: &context)
            return
        }

        // Check if this is a list item - needs special handling
        if let listItemRenderer = Tag.self as? any PDF.HTML.ListItemRenderer.Type {
            renderListItem(view, listItemRenderer: listItemRenderer, into: &buffer, context: &context)
            return
        }

        // Check if this is a table container - needs special handling
        if Tag.self is any PDF.HTML.TableContainer.Type {
            renderTableContainer(view, into: &buffer, context: &context)
            return
        }

        // Check if this is a table row
        if Tag.self is any PDF.HTML.TableRowContainer.Type {
            renderTableRow(view, into: &buffer, context: &context)
            return
        }

        // Check if this is a table cell
        if Tag.self is any PDF.HTML.TableCellContainer.Type {
            renderTableCell(view, into: &buffer, context: &context)
            return
        }

        // Table section containers (thead, tbody, tfoot) - just pass through to content
        if Tag.self is any PDF.HTML.TableSectionContainer.Type {
            if let content = view.content {
                Content._render(content, into: &buffer, context: &context)
            }
            return
        }

        // Helper to render based on Tag.flow
        func renderWithFlow() {
            switch Tag.flow {
            case .block:
                PDF.HTML.renderBlock(view.content, into: &buffer, context: &context)
            case .inline:
                PDF.HTML.renderInline(view.content, into: &buffer, context: &context)
            }
        }

        // Check if Tag provides custom styling
        if let tagRenderer = Tag.self as? any PDF.HTML.TagRenderer.Type {
            // Save current style and layout state
            let savedFont = context.pdf.font
            let savedFontSize = context.pdf.fontSize
            let savedColor = context.pdf.color
            let savedTextDecoration = context.pdf.textDecoration
            let savedTextBackgroundColor = context.pdf.textBackgroundColor
            let savedX = context.pdf.x
            let savedAvailableWidth = context.pdf.availableWidth
            let savedPreserveWhitespace = context.pdf.preserveWhitespace

            // Apply tag-specific style
            tagRenderer.applyStyle(to: &context.pdf, configuration: context.configuration)

            // Render with flow
            renderWithFlow()

            // Restore style and layout state
            context.pdf.font = savedFont
            context.pdf.fontSize = savedFontSize
            context.pdf.color = savedColor
            context.pdf.textDecoration = savedTextDecoration
            context.pdf.textBackgroundColor = savedTextBackgroundColor
            context.pdf.x = savedX
            context.pdf.availableWidth = savedAvailableWidth
            context.pdf.preserveWhitespace = savedPreserveWhitespace
        } else {
            // Default: just render with flow
            renderWithFlow()
        }
    }

    /// Render a list container (ul/ol)
    private static func renderListContainer<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        listContainer: any PDF.HTML.ListContainer.Type,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs
        _ = context.pdf.flushInlineRuns()

        // Push list type onto stack
        context.pdf.push(list: listContainer.listType())

        // Save and indent for list content
        let savedX = context.pdf.x
        let savedWidth = context.pdf.availableWidth
        let listIndent: PDF.UserSpace.Unit = 20
        context.pdf.x = PDF.UserSpace.X(PDF.UserSpace.Unit(context.pdf.x.value) + listIndent)
        context.pdf.availableWidth = PDF.UserSpace.Width(PDF.UserSpace.Unit(context.pdf.availableWidth.value) - listIndent)

        // Render list content
        if let content = view.content {
            Content._render(content, into: &buffer, context: &context)
        }

        // Flush and restore
        _ = context.pdf.flushInlineRuns()
        context.pdf.x = savedX
        context.pdf.availableWidth = savedWidth
        context.pdf.popList()
    }

    /// Render a list item (li)
    private static func renderListItem<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        listItemRenderer: any PDF.HTML.ListItemRenderer.Type,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs
        _ = context.pdf.flushInlineRuns()

        // Get the marker text
        let marker = context.pdf.nextListMarker()

        // Render marker at current position (left of content area)
        let markerWidth = context.pdf.font.stringWidth(marker + " ", atSize: context.pdf.fontSize)
        let markerX = PDF.UserSpace.X(PDF.UserSpace.Unit(context.pdf.x.value) - markerWidth)

        // Create text run for marker
        let markerRun = PDF.TextRun(
            text: marker,
            font: context.pdf.font,
            fontSize: context.pdf.fontSize,
            color: context.pdf.color
        )

        // Render marker inline run
        let savedInlineRuns = context.pdf.inlineRuns
        context.pdf.inlineRuns = [markerRun]

        // Calculate marker position
        let lineHeight = PDF.UserSpace.Height(context.pdf.lineHeightPoints)
        context.pdf.checkPageBreak(needing: lineHeight)

        // Manually render marker at left offset position
        let baselineY = PDF.UserSpace.Y(
            PDF.UserSpace.Unit(context.pdf.y.value) +
            context.pdf.font.metrics.ascender(atSize: context.pdf.fontSize)
        )
        context.pdf.add(.text(PDF.Render.TextOperation(
            text: marker,
            position: PDF.UserSpace.Coordinate(x: markerX, y: baselineY),
            font: context.pdf.font,
            size: context.pdf.fontSize,
            color: context.pdf.color
        )))

        // Restore inline runs
        context.pdf.inlineRuns = savedInlineRuns

        // Render content
        if let content = view.content {
            Content._render(content, into: &buffer, context: &context)
        }

        // Flush content
        _ = context.pdf.flushInlineRuns()
    }

    // MARK: - Table Rendering

    /// Render a table container
    private static func renderTableContainer<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs
        _ = context.pdf.flushInlineRuns()

        // Create table context with default 3 columns (will be updated by first row)
        let tableContext = PDF.HTML.TableContext(
            tableX: context.pdf.x,
            tableWidth: context.pdf.availableWidth,
            columnCount: 3
        )
        context.tableContext = tableContext

        // Render table content
        if let content = view.content {
            Content._render(content, into: &buffer, context: &context)
        }

        // Flush and clean up table context
        _ = context.pdf.flushInlineRuns()
        context.tableContext = nil
    }

    /// Render a table row
    private static func renderTableRow<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs
        _ = context.pdf.flushInlineRuns()

        guard context.tableContext != nil else {
            // Not in a table context, fall through to default rendering
            if let content = view.content {
                PDF.HTML.renderBlock(content, into: &buffer, context: &context)
            }
            return
        }

        // Check for page break BEFORE starting the row - ensure entire row fits
        let lineHeight = PDF.UserSpace.Height(context.pdf.lineHeightPoints)
        context.pdf.checkPageBreak(needing: lineHeight)

        // Reset column index for this row
        context.tableContext?.currentColumn = 0
        context.tableContext?.rowY = context.pdf.y

        // Save original X position
        let savedX = context.pdf.x

        // Render row content (cells will position themselves)
        if let content = view.content {
            Content._render(content, into: &buffer, context: &context)
        }

        // DON'T flush here - cells handle their own flushing

        // Restore X and advance to next row
        context.pdf.x = savedX
        context.pdf.advanceLine()
    }

    /// Render a table cell (td or th)
    private static func renderTableCell<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        guard let tableContext = context.tableContext else {
            // Not in a table context, fall through to default rendering
            if let content = view.content {
                PDF.HTML.renderInline(content, into: &buffer, context: &context)
            }
            return
        }

        // Get current column position
        let columnIndex = tableContext.currentColumn
        let cellX = tableContext.xForColumn(columnIndex)

        // Save state
        let savedFont = context.pdf.font
        let savedColor = context.pdf.color

        // Apply th styling if this is a header cell
        if let tagRenderer = Tag.self as? any PDF.HTML.TagRenderer.Type {
            tagRenderer.applyStyle(to: &context.pdf, configuration: context.configuration)
        }

        // Render cell content directly at position (no page break checking)
        // Calculate baseline Y for this row
        let baselineY = PDF.UserSpace.Y(
            PDF.UserSpace.Unit(tableContext.rowY.value) +
            context.pdf.font.metrics.ascender(atSize: context.pdf.fontSize)
        )

        // Build cell text by collecting inline runs
        if let content = view.content {
            // Temporarily collect text into inline runs
            let savedRuns = context.pdf.inlineRuns
            context.pdf.inlineRuns = []

            Content._render(content, into: &buffer, context: &context)

            // Render the collected text directly at cell position
            let cellText = context.pdf.inlineRuns.map { $0.text }.joined()
            if !cellText.isEmpty {
                context.pdf.add(.text(PDF.Render.TextOperation(
                    text: cellText,
                    position: PDF.UserSpace.Coordinate(
                        x: PDF.UserSpace.X(cellX.value + tableContext.cellPadding),
                        y: baselineY
                    ),
                    font: context.pdf.font,
                    size: context.pdf.fontSize,
                    color: context.pdf.color
                )))
            }

            // Restore inline runs (don't accumulate cell content)
            context.pdf.inlineRuns = savedRuns
        }

        // Advance to next column
        context.tableContext?.currentColumn = columnIndex + 1

        // Restore style state
        context.pdf.font = savedFont
        context.pdf.color = savedColor
    }
}
