// PDF.HTML.Context+Rendering.swift
// Rendering.Context conformance for HTML-to-PDF rendering.
//
// Maps the Rendering.Context protocol to PDF.HTML.Context, enabling
// the same Rendering.View tree to render through both HTML.Context
// (for byte output) and PDF.HTML.Context (for PDF pages) via pure
// static dispatch — eliminating PDF.HTML.View and Mirror-based dispatch.

import CSS_Standard
import HTML_Renderable
import Layout_Primitives
import PDF_Rendering
import Rendering_Primitives
import W3C_CSS_Shared

// MARK: - Rendering.Context Conformance

extension PDF.HTML.Context: Rendering.Context {

    // MARK: - Text

    public mutating func text(_ content: borrowing String) {
        let copy = copy content

        // Capture heading text for bookmarks
        if section.activeHeading != nil {
            if !section.activeHeading!.text.isEmpty {
                section.activeHeading!.text += " "
            }
            section.activeHeading!.text += copy
        }

        let linkURL = link.currentURL ?? link.currentInternalId.map { "#\($0)" }
        let runs = PDF.Context.Text.Run.runsWithSymbolSupport(
            text: copy,
            font: pdf.style.font,
            fontSize: pdf.style.fontSize,
            color: pdf.style.color,
            textDecoration: pdf.style.textMarkup,
            verticalOffset: pdf.style.verticalOffset,
            linkURL: linkURL
        )
        for run in runs {
            pdf.append(inline: run)
        }
    }

    // MARK: - Breaks

    public mutating func lineBreak() {
        pdf.flush.inline()
        pdf.advance.line()
    }

    public mutating func thematicBreak() {
        pdf.flush.inline()
        let spacing = (configuration.defaultFontSize * configuration.horizontalGapEm).height
        pdf.advance(spacing)
        let layoutBox = pdf.layoutBox
        pdf.emit.line(
            from: PDF.UserSpace.Coordinate(x: layoutBox.llx, y: layoutBox.lly),
            to: PDF.UserSpace.Coordinate(x: layoutBox.urx, y: layoutBox.lly),
            color: .gray(0.5),
            width: .init(1)
        )
        pdf.advance(spacing)
    }

    // MARK: - Media

    public mutating func image(source: String, alt: String) {
        pdf.flush.inline()
        let run = PDF.Context.Text.Run(
            text: alt.isEmpty ? "[image]" : "[\(alt)]",
            font: pdf.style.font.italic ?? pdf.style.font,
            fontSize: pdf.style.fontSize,
            color: .gray(0.5)
        )
        pdf.append(inline: run)
        pdf.flush.inline()
    }

    // MARK: - Page

    public mutating func pageBreak() {
        pdf.flush.inline()
        pdf.flush.text()
        pdf.page.new()
    }

    // MARK: - Attributes

    public mutating func set(attribute name: String, _ value: String?) {
        if let value {
            attributes[name] = value
        } else {
            attributes.remove(name)
        }
    }

    public mutating func add(class name: String) {
        // No-op: PDF doesn't use CSS class names.
    }

    public mutating func write(raw bytes: [UInt8]) {
        // No-op: raw HTML bytes have no PDF representation.
    }

    public mutating func register(
        style declaration: String,
        atRule: String?,
        selector: String?,
        pseudo: String?
    ) -> String? {
        // PDF doesn't generate CSS class names.
        nil
    }

    // MARK: - Inline Style Application

    public mutating func apply(inlineStyle property: Any) -> Bool {
        // Unwrap Optional if needed
        let unwrapped: Any
        let mirror = Mirror(reflecting: property)
        if mirror.displayStyle == .optional {
            guard let first = mirror.children.first else { return false }
            unwrapped = first.value
        } else {
            unwrapped = property
        }

        var handled = false

        if let modifier = unwrapped as? any PDF.HTML.Style.Modifier {
            modifier.apply(to: &pdf, configuration: configuration)
            handled = true
        }

        if let htmlModifier = unwrapped as? any PDF.HTML.Style.Context.Modifier {
            htmlModifier.apply(to: &self)
            handled = true
        }

        // Apply box model after style modifiers set margins/padding
        if handled {
            applyBoxModel()
        }

        return handled
    }

    // MARK: - Block Structure

    public static func _pushBlock(
        _ context: inout Self,
        role: Rendering.Semantic.Block?,
        style: Rendering.Style
    ) {
        if context.pdf.hasInlineRuns {
            context.pdf.flush.inline()
        }
        PDF.Context._pushBlock(&context.pdf, role: role, style: style)
    }

    public static func _popBlock(_ context: inout Self) {
        if context.pdf.hasInlineRuns {
            context.pdf.flush.inline()
        }
        PDF.Context._popBlock(&context.pdf)
    }

    // MARK: - Inline Structure

    public static func _pushInline(
        _ context: inout Self,
        role: Rendering.Semantic.Inline?,
        style: Rendering.Style
    ) {
        PDF.Context._pushInline(&context.pdf, role: role, style: style)
    }

    public static func _popInline(_ context: inout Self) {
        PDF.Context._popInline(&context.pdf)
    }

    // MARK: - Lists

    public static func _pushList(
        _ context: inout Self,
        kind: Rendering.Semantic.List,
        start: Int?
    ) {
        PDF.Context._pushList(&context.pdf, kind: kind, start: start)
    }

    public static func _popList(_ context: inout Self) {
        PDF.Context._popList(&context.pdf)
    }

    public static func _pushItem(_ context: inout Self) {
        PDF.Context._pushItem(&context.pdf)
    }

    public static func _popItem(_ context: inout Self) {
        PDF.Context._popItem(&context.pdf)
    }

    // MARK: - Links

    public static func _pushLink(
        _ context: inout Self,
        destination: borrowing String
    ) {
        PDF.Context._pushLink(&context.pdf, destination: destination)
    }

    public static func _popLink(_ context: inout Self) {
        PDF.Context._popLink(&context.pdf)
    }

    // MARK: - Attributes

    public static func _pushAttributes(_ context: inout Self) {
        context.elementStack.append(Element.Scope(
            tagName: "_attributes",
            isBlock: false,
            style: context.pdf.style,
            llx: context.pdf.layoutBox.llx,
            urx: context.pdf.layoutBox.urx,
            preserveWhitespace: context.pdf.preserveWhitespace,
            linkURL: context.link.currentURL,
            internalLinkId: context.link.currentInternalId,
            savedTable: nil,
            savedPendingMargin: context.pendingBottomMargin
        ))
    }

    public static func _popAttributes(_ context: inout Self) {
        if let scope = context.elementStack.popLast(), scope.tagName == "_attributes" {
            context.attributes = .init()
        }
    }

    // MARK: - Elements

    public static func _pushElement(
        _ context: inout Self,
        tagName: String,
        isBlock: Bool,
        isVoid: Bool,
        isPreElement: Bool
    ) {
        // Handle void elements
        if isVoid {
            handleVoidElement(tagName, context: &context)
            return
        }

        // Save element-scoped state
        let scope = Element.Scope(
            tagName: tagName,
            isBlock: isBlock,
            style: context.pdf.style,
            llx: context.pdf.layoutBox.llx,
            urx: context.pdf.layoutBox.urx,
            preserveWhitespace: context.pdf.preserveWhitespace,
            linkURL: context.link.currentURL,
            internalLinkId: context.link.currentInternalId,
            savedTable: tagName == "table" ? context.table : nil,
            savedPendingMargin: context.pendingBottomMargin
        )
        context.elementStack.append(scope)

        // Apply tag-specific style
        HTML.Element.Tag<Never>.applyTagStyle(tagName, context: &context)

        // Handle anchor tags: extract href from attributes
        if tagName == "a" {
            if let href = context.attributes["href"] {
                if href.hasPrefix("#") {
                    context.link.currentInternalId = String(href.dropFirst())
                } else {
                    context.link.currentURL = href
                }
            }
        }

        // Handle named destinations (id attribute)
        if let elementId = context.attributes["id"], !elementId.isEmpty {
            let pageNumber = context.pdf.completedPages.count + 1
            let yPosition = context.pdf.layoutBox.lly
            context.link.destinations[elementId] = PDF.HTML.Context.Link.Destination(
                pageNumber: pageNumber,
                yPosition: yPosition
            )
        }

        if isBlock {
            if context.pdf.hasInlineRuns {
                context.pdf.flush.inline()
            }

            // Block margins (CSS margin collapsing)
            let isNestedList = (tagName == "ul" || tagName == "ol") && context.pdf.listDepth > 0
            if !isNestedList,
               let margins = HTML.Element.Tag<Never>.blockMargins(
                   for: tagName,
                   configuration: context.configuration
               ) {
                let currentSize = context.pdf.style.fontSize
                let marginTop = PDF.UserSpace.Size<1>(
                    margins.top,
                    currentSize: currentSize,
                    baseFontSize: context.configuration.defaultFontSize
                ).height
                let marginBottom = PDF.UserSpace.Size<1>(
                    margins.bottom,
                    currentSize: currentSize,
                    baseFontSize: context.configuration.defaultFontSize
                ).height

                if marginTop > .init(0) || marginBottom > .init(0) {
                    context.applyCollapsedMargin(top: marginTop, bottom: marginBottom)
                }
            }

            // Heading tracking for bookmarks
            if let headingLevel = HTML.Element.Tag<Never>.headingLevel(for: tagName) {
                pushHeading(level: headingLevel, tagName: tagName, context: &context)
            }

            // Handle deferred keep-with-next content
            if let deferred = context.deferredKeepWithNextRender {
                context.deferredKeepWithNextRender = nil
                let fullPageHeight = context.configuration.content.height
                if deferred.measuredHeight > fullPageHeight * context.configuration.deferredHeaderThreshold {
                    deferred.render(&context)
                } else {
                    let oneLineHeight = context.pdf.style.line.height
                    let marginTop = PDF.UserSpace.Size<1>(
                        HTML.Element.Tag<Never>.blockMargins(
                            for: tagName,
                            configuration: context.configuration
                        )?.top ?? .length(.em(0)),
                        currentSize: context.pdf.style.fontSize,
                        baseFontSize: context.configuration.defaultFontSize
                    ).height
                    let minContentHeight = marginTop + oneLineHeight
                    let totalNeeded = deferred.measuredHeight + minContentHeight
                    if context.pdf.page.exceeds(adding: totalNeeded) {
                        context.pdf.page.new()
                    }
                    deferred.render(&context)
                }
            }

            // Tag-specific block setup
            pushBlockElement(tagName, context: &context)
        } else {
            // Tag-specific inline setup
            pushInlineElement(tagName, context: &context)
        }
    }

    public static func _popElement(_ context: inout Self, isBlock: Bool) {
        guard let scope = context.elementStack.popLast() else { return }

        if isBlock {
            popBlockElement(scope, context: &context)

            if context.pdf.hasInlineRuns {
                context.pdf.flush.inline()
            }
        } else {
            popInlineElement(scope.tagName, context: &context)
        }

        // Restore element-scoped state
        context.pdf.style = scope.style
        context.pdf.layoutBox.llx = scope.llx
        context.pdf.layoutBox.urx = scope.urx
        context.pdf.preserveWhitespace = scope.preserveWhitespace
        context.link.currentURL = scope.linkURL
        context.link.currentInternalId = scope.internalLinkId
    }

    // MARK: - Style Scope

    public static func _pushStyle(_ context: inout Self) {
        context.styleScopeStack.append(Style.Snapshot(from: context))
    }

    public static func _popStyle(_ context: inout Self) {
        // Apply bottom padding and margin before restoring
        if let paddingBottom = context.pdf.paddingBottom, paddingBottom > .zero {
            context.pdf.advance(paddingBottom)
        }
        if let marginBottom = context.pdf.marginBottom, marginBottom > .zero {
            context.pdf.advance(marginBottom)
        }

        // Handle force page break after
        if context.forcePageBreakAfter {
            context.pdf.flush.inline()
            context.pdf.page.new()
            context.forcePageBreakAfter = false
        }

        // Restore saved state
        if let snapshot = context.styleScopeStack.popLast() {
            snapshot.restore(to: &context)
        }
    }
}

// MARK: - Box Model Application

extension PDF.HTML.Context {
    /// Apply CSS box model (margins, padding, explicit width) to layout.
    ///
    /// Called after style modifiers set margin/padding properties.
    mutating func applyBoxModel() {
        if let marginTop = pdf.marginTop, marginTop > .zero {
            pdf.advance(marginTop)
        }
        if let marginLeft = pdf.marginLeft {
            pdf.layoutBox.llx = pdf.layoutBox.llx + marginLeft
        }
        if let marginRight = pdf.marginRight {
            pdf.layoutBox.urx = pdf.layoutBox.urx - marginRight
        }
        if let paddingTop = pdf.paddingTop, paddingTop > .zero {
            pdf.advance(paddingTop)
        }
        if let paddingLeft = pdf.paddingLeft {
            pdf.layoutBox.llx = pdf.layoutBox.llx + paddingLeft
        }
        if let paddingRight = pdf.paddingRight {
            pdf.layoutBox.urx = pdf.layoutBox.urx - paddingRight
        }
        if let explicitWidth = pdf.explicitWidth {
            pdf.layoutBox.urx = pdf.layoutBox.llx + explicitWidth
        }
    }
}

// MARK: - Void Element Handling

extension PDF.HTML.Context {
    private static func handleVoidElement(
        _ tagName: String,
        context: inout PDF.HTML.Context
    ) {
        switch tagName {
        case "br":
            context.pdf.flush.inline()
            context.pdf.advance.line()
        case "hr":
            if context.pdf.hasInlineRuns {
                context.pdf.flush.inline()
            }
            let spacing = (context.configuration.defaultFontSize * context.configuration.horizontalGapEm).height
            context.pdf.advance(spacing)
            let layoutBox = context.pdf.layoutBox
            context.pdf.emit.line(
                from: PDF.UserSpace.Coordinate(x: layoutBox.llx, y: layoutBox.lly),
                to: PDF.UserSpace.Coordinate(x: layoutBox.urx, y: layoutBox.lly),
                color: .gray(0.5),
                width: .init(1)
            )
            context.pdf.advance(spacing)
        default:
            break
        }
    }
}

// MARK: - Block Element Push/Pop

extension PDF.HTML.Context {
    /// Tag-specific setup for block elements (called from _pushElement).
    private static func pushBlockElement(
        _ tagName: String,
        context: inout PDF.HTML.Context
    ) {
        switch tagName {
        // Table elements — basic block fallback (proper table handling is TODO)
        case "table":
            let savedTableContext = context.table
            let tableStartY = context.pdf.layoutBox.lly
            let availableWidth = context.pdf.layoutBox.width
            let cellPadding = context.configuration.table.cell.padding
            let defaultRowHeight = context.pdf.style.line.height + cellPadding.height * 2
            let tableX = context.pdf.layoutBox.llx
            let tableBounds = PDF.UserSpace.Rectangle(
                x: tableX,
                y: tableStartY,
                width: availableWidth,
                height: defaultRowHeight
            )
            context.table = PDF.HTML.Context.Table(
                bounds: tableBounds,
                columnWidths: [],
                rowHeights: [],
                cellPadding: cellPadding,
                borderColor: context.configuration.table.border.color,
                borderWidth: context.configuration.table.border.width,
                headerBackground: context.configuration.table.headerBackground,
                alternatingRowColor: context.configuration.table.alternatingRowColor
            )
            context.table?.totalRowsRendered = 0
            context.resetMarginCollapsing()

        case "thead":
            context.with(\.table) { tc in
                tc.header.startCapturing()
            }

        case "tbody", "tfoot":
            break // Pass-through

        case "tr":
            // TODO: Full table row push (page breaks, header repetition, column measurement)
            if var tableCtx = context.table {
                tableCtx.currentColumn = 0
                tableCtx.maxCellHeightInCurrentRow = PDF.UserSpace.Height(0)
                tableCtx.pendingCellBorders = []
                tableCtx.bounds = PDF.UserSpace.Rectangle(
                    x: tableCtx.bounds.llx,
                    y: context.pdf.layoutBox.lly,
                    width: tableCtx.bounds.width,
                    height: context.pdf.style.line.height + tableCtx.cell.padding.height * 2
                )
                context.table = tableCtx
            }

        case "td", "th":
            // TODO: Full table cell push (column positioning, measurement mode)
            if var tableCtx = context.table, tableCtx.columnsInitialized {
                let column = tableCtx.currentColumn
                let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
                if column < tableCtx.columnCount {
                    let cellX = tableCtx.xForColumn(column)
                    let cellWidth = tableCtx.widthForColumns(column, count: colspan)
                    let cellPadding = tableCtx.cell.padding
                    let contentX = cellX + cellPadding.width
                    let contentWidth = cellWidth - cellPadding.width * 2
                    let contentY = tableCtx.bounds.lly + cellPadding.height
                    let contentHeight = tableCtx.bounds.height - cellPadding.height * 2
                    // Save layout box (restored in popElement)
                    context.pdf.layoutBox = PDF.UserSpace.Rectangle(
                        x: contentX, y: contentY,
                        width: contentWidth, height: contentHeight
                    )
                    if tagName == "th" {
                        context.pdf.style.font = context.pdf.style.font.bold
                    }
                }
            }

        // List containers
        case "ol", "ul":
            if let listType = HTML.Element.Tag<Never>.listType(for: tagName) {
                context.pdf.push(list: listType)
                let indent = context.configuration.indent.list
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + indent
                let savedPendingMargin = context.pendingBottomMargin
                context.pendingBottomMargin = .init(0)
                // Store the saved margin in the element stack's last entry
                if var last = context.elementStack.popLast() {
                    context.elementStack.append(Element.Scope(
                        tagName: last.tagName,
                        isBlock: last.isBlock,
                        style: last.style,
                        llx: last.llx,
                        urx: last.urx,
                        preserveWhitespace: last.preserveWhitespace,
                        linkURL: last.linkURL,
                        internalLinkId: last.internalLinkId,
                        savedTable: last.savedTable,
                        savedPendingMargin: savedPendingMargin
                    ))
                }
            }

        // List items
        case "li":
            let marker = context.pdf.nextListMarker()
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
            let markerGap = (context.pdf.style.fontSize * context.configuration.horizontalGapEm).width
            let markerX = context.pdf.layoutBox.llx - markerWidth - markerGap
            context.pdf.pendingListMarker = (marker: marker, x: markerX)

        default:
            break
        }
    }

    /// Tag-specific cleanup for block elements (called from _popElement).
    private static func popBlockElement(
        _ scope: Element.Scope,
        context: inout PDF.HTML.Context
    ) {
        switch scope.tagName {
        case "table":
            // Draw table right and bottom borders
            if let tc = context.table {
                HTML.Element.Tag<Never>.drawTableRightAndBottomBorders(
                    tableCtx: tc,
                    context: &context
                )
            }
            context.pdf.advance(
                (context.configuration.defaultFontSize * context.configuration.horizontalGapEm).height
            )
            // Restore saved table context from scope
            context.table = scope.savedTable

        case "thead":
            context.with(\.table) { tc in
                tc.header.finalizeCapture()
                if !tc.rowHeights.isEmpty {
                    tc.header.rowHeight = tc.rowHeights[0]
                }
            }

        case "tbody", "tfoot":
            break

        case "tr":
            popTableRow(context: &context)

        case "td", "th":
            popTableCell(isHeader: scope.tagName == "th", context: &context)

        case "ol", "ul":
            if context.pdf.hasInlineRuns {
                context.pdf.flush.inline()
            }
            _ = context.pdf.listStack.popLast()
            // Restore the pending margin saved during push
            context.pendingBottomMargin = scope.savedPendingMargin

        case "li":
            // Flush inline runs BEFORE clearing marker — otherwise the marker
            // is consumed by emitLine during flush, but already nil.
            if context.pdf.hasInlineRuns {
                context.pdf.flush.inline()
            }
            context.pdf.pendingListMarker = nil

        default:
            // Finalize heading if popping a heading element
            if let heading = context.section.activeHeading,
               HTML.Element.Tag<Never>.headingLevel(for: scope.tagName) != nil {
                let text = String(heading.text.drop(while: { $0 == " " }).reversed().drop(while: { $0 == " " }).reversed())
                if !text.isEmpty {
                    context.section.headings.append(.init(
                        level: heading.level,
                        text: text,
                        pageNumber: heading.pageNumber,
                        yPosition: heading.yPosition
                    ))
                    if heading.level <= 3 {
                        context.section.currentTitle = text
                        context.section.pageTitles[heading.pageNumber] = text
                    }
                }
                context.section.activeHeading = nil
            }
        }
    }
}

// MARK: - Inline Element Push/Pop

extension PDF.HTML.Context {
    private static func pushInlineElement(
        _ tagName: String,
        context: inout PDF.HTML.Context
    ) {
        if tagName == "q" {
            // Opening curly quote
            let openQuote = PDF.Context.Text.Run(
                bytes: [0x93],
                font: context.pdf.style.font,
                fontSize: context.pdf.style.fontSize,
                color: context.pdf.style.color,
                textDecoration: context.pdf.style.textMarkup,
                verticalOffset: context.pdf.style.verticalOffset
            )
            context.pdf.append(inline: openQuote)
        }
    }

    private static func popInlineElement(
        _ tagName: String,
        context: inout PDF.HTML.Context
    ) {
        if tagName == "q" {
            // Closing curly quote
            let closeQuote = PDF.Context.Text.Run(
                bytes: [0x94],
                font: context.pdf.style.font,
                fontSize: context.pdf.style.fontSize,
                color: context.pdf.style.color,
                textDecoration: context.pdf.style.textMarkup,
                verticalOffset: context.pdf.style.verticalOffset
            )
            context.pdf.append(inline: closeQuote)
        }
    }
}

// MARK: - Heading Tracking

extension PDF.HTML.Context {
    private static func pushHeading(
        level: Int,
        tagName: String,
        context: inout PDF.HTML.Context
    ) {
        let headingFontSize = context.configuration.headingSize(level: level)
        let headingLineHeight = (headingFontSize * context.pdf.style.lineHeight).height
        context.pdf.page.ensure(height: headingLineHeight)

        let pageNumber = context.pdf.completedPages.count + 1
        let yPosition = context.pdf.layoutBox.lly

        // Start capturing text for this heading (finalized in popBlockElement)
        context.section.activeHeading = .init(
            level: level,
            pageNumber: pageNumber,
            yPosition: yPosition
        )
    }
}

// MARK: - Table Row/Cell Pop Helpers

extension PDF.HTML.Context {
    /// Finalize a table row: compute row height, draw borders, advance Y.
    private static func popTableRow(context: inout PDF.HTML.Context) {
        guard var tableCtx = context.table else { return }

        if context.pdf.hasInlineRuns {
            context.pdf.flush.inline()
        }

        let minRowHeight = context.pdf.style.line.height + tableCtx.cell.padding.height * 2
        let actualRowHeight = tableCtx.maxCellHeightInCurrentRow > minRowHeight
            ? tableCtx.maxCellHeightInCurrentRow
            : minRowHeight

        // Draw cell borders with correct row height
        let rowStartY = tableCtx.bounds.lly
        for pending in tableCtx.pendingCellBorders {
            let cellX = tableCtx.xForColumn(pending.column)
            let cellWidth = tableCtx.widthForColumns(pending.column, count: pending.colspan)
            let cellBounds = PDF.UserSpace.Rectangle(
                x: cellX,
                y: rowStartY,
                width: cellWidth,
                height: actualRowHeight
            )
            HTML.Element.Tag<Never>.drawCellBorder(
                bounds: cellBounds,
                tableCtx: tableCtx,
                context: &context
            )
        }

        // Update row heights
        tableCtx.rowHeights.append(actualRowHeight)

        // Advance past this row
        let newY = rowStartY + actualRowHeight
        context.pdf.layoutBox.lly = newY
        tableCtx.tableEndY = newY
        tableCtx.currentFragmentEndY = newY
        tableCtx.totalRowsRendered += 1
        tableCtx.currentColumn = 0
        tableCtx.pendingCellBorders = []
        context.table = tableCtx
    }

    /// Finalize a table cell: track height, register pending border.
    private static func popTableCell(
        isHeader: Bool,
        context: inout PDF.HTML.Context
    ) {
        if context.pdf.hasInlineRuns {
            context.pdf.flush.inline()
        }

        let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
        let textAlignment = context.pdf.style.textAlign

        context.with(\.table) { tc in
            tc.pendingCellBorders.append(.init(
                column: tc.currentColumn,
                colspan: colspan,
                rowspan: 1,
                isHeader: isHeader,
                textAlignment: textAlignment
            ))
            tc.currentColumn += colspan
        }
    }
}
