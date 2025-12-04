// HTML.Element+PDF.HTML.View.swift
// HTML.Element rendering using WHATWG_HTML.Element.flow

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension HTML.Element: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Check if this is a list container (ul, ol) - needs special handling
        if let listContainer = Tag.self as? any PDF.HTML.ListContainer.Type {
            renderListContainer(
                view,
                listContainer: listContainer,
                into: &buffer,
                context: &context,
                configuration: configuration
            )
            return
        }

        // Check if this is a list item - needs special handling
        if let listItemRenderer = Tag.self as? any PDF.HTML.ListItemRenderer.Type {
            renderListItem(
                view,
                listItemRenderer: listItemRenderer,
                into: &buffer,
                context: &context,
                configuration: configuration
            )
            return
        }

        // Helper to render based on Tag.flow
        func renderWithFlow() {
            switch Tag.flow {
            case .block:
                PDF.HTML.renderBlock(
                    view.content,
                    into: &buffer,
                    context: &context,
                    configuration: configuration
                )
            case .inline:
                PDF.HTML.renderInline(
                    view.content,
                    into: &buffer,
                    context: &context,
                    configuration: configuration
                )
            }
        }

        // Check if Tag provides custom styling
        if let tagRenderer = Tag.self as? any PDF.HTML.TagRenderer.Type {
            // Save current style and layout state
            let savedFont = context.font
            let savedFontSize = context.fontSize
            let savedTextDecoration = context.textDecoration
            let savedTextBackgroundColor = context.textBackgroundColor
            let savedX = context.x
            let savedAvailableWidth = context.availableWidth
            let savedPreserveWhitespace = context.preserveWhitespace

            // Apply tag-specific style
            tagRenderer.applyStyle(to: &context, configuration: configuration)

            // Render with flow
            renderWithFlow()

            // Restore style and layout state
            context.font = savedFont
            context.fontSize = savedFontSize
            context.textDecoration = savedTextDecoration
            context.textBackgroundColor = savedTextBackgroundColor
            context.x = savedX
            context.availableWidth = savedAvailableWidth
            context.preserveWhitespace = savedPreserveWhitespace
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
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs
        _ = context.flushInlineRuns()

        // Push list type onto stack
        context.push(list: listContainer.listType())

        // Save and indent for list content
        let savedX = context.x
        let savedWidth = context.availableWidth
        let listIndent: PDF.UserSpace.Unit = 20
        context.x = PDF.UserSpace.X(PDF.UserSpace.Unit(context.x.value) + listIndent)
        context.availableWidth = PDF.UserSpace.Width(PDF.UserSpace.Unit(context.availableWidth.value) - listIndent)

        // Render list content
        if let content = view.content {
            Content._render(content, into: &buffer, context: &context, configuration: configuration)
        }

        // Flush and restore
        _ = context.flushInlineRuns()
        context.x = savedX
        context.availableWidth = savedWidth
        context.popList()
    }

    /// Render a list item (li)
    private static func renderListItem<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        listItemRenderer: any PDF.HTML.ListItemRenderer.Type,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Flush any pending inline runs
        _ = context.flushInlineRuns()

        // Get the marker text
        let marker = context.nextListMarker()

        // Render marker at current position (left of content area)
        let markerWidth = context.font.stringWidth(marker + " ", atSize: context.fontSize)
        let markerX = PDF.UserSpace.X(PDF.UserSpace.Unit(context.x.value) - markerWidth)

        // Create text run for marker
        let markerRun = PDF.TextRun(
            text: marker,
            font: context.font,
            fontSize: context.fontSize,
            color: context.color
        )

        // Render marker inline run
        let savedInlineRuns = context.inlineRuns
        context.inlineRuns = [markerRun]

        // Calculate marker position
        let lineHeight = PDF.UserSpace.Height(context.lineHeightPoints)
        context.checkPageBreak(needing: lineHeight)

        // Manually render marker at left offset position
        let baselineY = PDF.UserSpace.Y(
            PDF.UserSpace.Unit(context.y.value) +
            context.font.metrics.ascender(atSize: context.fontSize)
        )
        context.add(.text(PDF.Render.TextOperation(
            text: marker,
            position: PDF.UserSpace.Coordinate(x: markerX, y: baselineY),
            font: context.font,
            size: context.fontSize,
            color: context.color
        )))

        // Restore inline runs
        context.inlineRuns = savedInlineRuns

        // Render content
        if let content = view.content {
            Content._render(content, into: &buffer, context: &context, configuration: configuration)
        }

        // Flush content
        _ = context.flushInlineRuns()
    }
}
