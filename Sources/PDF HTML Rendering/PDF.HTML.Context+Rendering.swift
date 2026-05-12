// PDF.HTML.Context+Render.swift
// Render_Primitives.Render.Context conformance for HTML-to-PDF rendering.
//
// Maps the Render_Primitives.Render.Context protocol to PDF.HTML.Context, enabling
// the same Render_Primitives.Render.View tree to render through both HTML.Context
// (for byte output) and PDF.HTML.Context (for PDF pages) via pure
// static dispatch — eliminating PDF.HTML.View and Mirror-based dispatch.

import HTML_Rendering_Core
import Layout_Primitives
import PDF_Rendering
import Render_Primitives

// MARK: - Render_Primitives.Render.Context Conformance

extension PDF.HTML.Context {

    // MARK: - Text

    public mutating func text(_ content: borrowing String) {
        let copy = copy content

        if table?.recording != nil {
            table!.recording!.commands.append(.text(copy))
            return
        }

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
        if table?.recording != nil {
            table!.recording!.commands.append(.lineBreak)
            return
        }
        pdf.flush.inline()
        pdf.advance.line()
    }

    public mutating func thematicBreak() {
        if table?.recording != nil {
            table!.recording!.commands.append(.thematicBreak)
            return
        }
        pdf.flush.inline()
        let spacing = (configuration.defaultFontSize * configuration.horizontalGapEm).height
        pdf.advance(spacing)
        let layoutBox = pdf.layout.box
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
        if table?.recording != nil {
            table!.recording!.commands.append(.image(source: source, alt: alt))
            return
        }
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
        if table?.recording != nil {
            table!.recording!.commands.append(.pageBreak)
            return
        }
        pdf.flush.inline()
        pdf.flush.text()
        pdf.page.new()
    }

    // MARK: - Attributes

    public mutating func set(attribute name: String, _ value: String?) {
        if table?.recording != nil {
            table!.recording!.commands.append(.setAttribute(name: name, value: value))
            if name == "colspan" {
                table!.recording!.pendingColspan = Int(value ?? "1") ?? 1
            }
            return
        }
        if let value {
            attributes[name] = value
        } else {
            attributes.remove(name)
        }
    }

    public mutating func add(class name: String) {
        if table?.recording != nil {
            table!.recording!.commands.append(.addClass(name))
            return
        }
        // No-op: PDF doesn't use CSS class names.
    }

    public mutating func write(raw bytes: [UInt8]) {
        if table?.recording != nil {
            table!.recording!.commands.append(.writeRaw(bytes))
            return
        }
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
        if table?.recording != nil {
            table!.recording!.commands.append(.inlineStyle(property))
            Self.captureCellWidthHint(from: property, into: &table!.recording!)
            return true
        }

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

    // MARK: - Recording Helper

    /// Record a command if in table first-row recording mode.
    /// Returns `true` if the command was recorded (caller should return early).
    @inline(always)
    private static func record(
        _ command: Table.Recording.Command,
        context: inout Self
    ) -> Bool {
        guard context.table?.recording != nil else { return false }
        context.table!.recording!.commands.append(command)
        return true
    }

    /// Extract a CSS `width: <percentage>` hint from a recorded inline-style
    /// property and buffer it for the next `<td>`/`<th>` push at recording
    /// depth 0. Only the percentage form is consumed; length-form (px/em/cm)
    /// hints fall through as uniform-weight, a documented gap for the current
    /// invoice corpus (verified to use only %-form). Optional unwrapping
    /// mirrors the runtime dispatch path at `apply(inlineStyle:)`.
    private static func captureCellWidthHint(
        from property: Any,
        into recording: inout PDF.HTML.Context.Table.Recording
    ) {
        let unwrapped: Any
        let mirror = Mirror(reflecting: property)
        if mirror.displayStyle == .optional {
            guard let first = mirror.children.first else { return }
            unwrapped = first.value
        } else {
            unwrapped = property
        }
        guard let width = unwrapped as? W3C_CSS_BoxModel.Width else { return }
        if case .lengthPercentage(.percentage(let p)) = width {
            recording.pendingCellWidthPercent = p.value
        }
    }

    // MARK: - Block Structure

    public static func _pushBlock(
        _ context: inout Self,
        role: Render_Primitives.Render.Semantic.Block?,
        style: Render_Primitives.Render.Style
    ) {
        if record(.pushBlock(role: role, style: style), context: &context) { return }
        if context.pdf.inline.hasRuns {
            context.pdf.flush.inline()
        }
        PDF.Context._pushBlock(&context.pdf, role: role, style: style)
    }

    public static func _popBlock(_ context: inout Self) {
        if record(.popBlock, context: &context) { return }
        if context.pdf.inline.hasRuns {
            context.pdf.flush.inline()
        }
        PDF.Context._popBlock(&context.pdf)
    }

    // MARK: - Inline Structure

    public static func _pushInline(
        _ context: inout Self,
        role: Render_Primitives.Render.Semantic.Inline?,
        style: Render_Primitives.Render.Style
    ) {
        if record(.pushInline(role: role, style: style), context: &context) { return }
        PDF.Context._pushInline(&context.pdf, role: role, style: style)
    }

    public static func _popInline(_ context: inout Self) {
        if record(.popInline, context: &context) { return }
        PDF.Context._popInline(&context.pdf)
    }

    // MARK: - Lists

    public static func _pushList(
        _ context: inout Self,
        kind: Render_Primitives.Render.Semantic.List,
        start: Int?
    ) {
        if record(.pushList(kind: kind, start: start), context: &context) { return }
        PDF.Context._pushList(&context.pdf, kind: kind, start: start)
    }

    public static func _popList(_ context: inout Self) {
        if record(.popList, context: &context) { return }
        PDF.Context._popList(&context.pdf)
    }

    public static func _pushItem(_ context: inout Self) {
        if record(.pushItem, context: &context) { return }
        PDF.Context._pushItem(&context.pdf)
    }

    public static func _popItem(_ context: inout Self) {
        if record(.popItem, context: &context) { return }
        PDF.Context._popItem(&context.pdf)
    }

    // MARK: - Links

    public static func _pushLink(
        _ context: inout Self,
        destination: borrowing String
    ) {
        if context.table?.recording != nil {
            context.table!.recording!.commands.append(.pushLink(destination: copy destination))
            return
        }
        PDF.Context._pushLink(&context.pdf, destination: destination)
    }

    public static func _popLink(_ context: inout Self) {
        if record(.popLink, context: &context) { return }
        PDF.Context._popLink(&context.pdf)
    }

    // MARK: - Attributes

    public static func _pushAttributes(_ context: inout Self) {
        if record(.pushAttributes, context: &context) { return }
        context.elementStack.append(Element.Scope(
            tagName: "_attributes",
            isBlock: false,
            style: context.pdf.style,
            llx: context.pdf.layout.box.llx,
            urx: context.pdf.layout.box.urx,
            preserveWhitespace: context.pdf.mode.preserveWhitespace,
            linkURL: context.link.currentURL,
            internalLinkId: context.link.currentInternalId,
            savedTable: nil,
            savedPendingMargin: context.pendingBottomMargin
        ))
    }

    public static func _popAttributes(_ context: inout Self) {
        if record(.popAttributes, context: &context) { return }
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
        // Recording mode: capture commands for first-row column measurement
        if context.table?.recording != nil {
            context.table!.recording!.commands.append(
                .pushElement(tagName: tagName, isBlock: isBlock, isVoid: isVoid, isPreElement: isPreElement)
            )
            if !isVoid {
                // Track grid columns at depth 0 (direct cell children of the row)
                if context.table!.recording!.elementDepth == 0
                    && (tagName == "td" || tagName == "th") {
                    let columnIdx = context.table!.recording!.columnCount
                    if let weight = context.table!.recording!.pendingCellWidthPercent {
                        context.table!.recording!.columnWidthWeights[columnIdx] = weight
                        context.table!.recording!.pendingCellWidthPercent = nil
                    }
                    context.table!.recording!.columnCount += context.table!.recording!.pendingColspan
                    context.table!.recording!.pendingColspan = 1
                }
                context.table!.recording!.elementDepth += 1
            }
            return
        }

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
            llx: context.pdf.layout.box.llx,
            urx: context.pdf.layout.box.urx,
            preserveWhitespace: context.pdf.mode.preserveWhitespace,
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
            let yPosition = context.pdf.layout.box.lly
            context.link.destinations[elementId] = PDF.HTML.Context.Link.Destination(
                pageNumber: pageNumber,
                yPosition: yPosition
            )
        }

        if isBlock {
            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }

            // Block margins (CSS margin collapsing)
            let isNestedList = (tagName == "ul" || tagName == "ol") && context.pdf.list.depth > 0
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

            // Tag-specific block setup
            pushBlockElement(tagName, context: &context)
        } else {
            // Tag-specific inline setup
            pushInlineElement(tagName, context: &context)
        }
    }

    public static func _popElement(_ context: inout Self, isBlock: Bool) {
        // Recording mode: track element depth
        if context.table?.recording != nil {
            context.table!.recording!.elementDepth -= 1
            if context.table!.recording!.elementDepth < 0 {
                // Row pop reached — finalize column widths and replay
                let recording = context.table!.recording!
                context.table!.recording = nil
                finalizeFirstRow(recording, context: &context)
                // Fall through to normal pop logic for the TR
            } else {
                context.table!.recording!.commands.append(.popElement(isBlock: isBlock))
                return
            }
        }

        guard let scope = context.elementStack.popLast() else { return }

        if isBlock {
            popBlockElement(scope, context: &context)

            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
        } else {
            popInlineElement(scope.tagName, context: &context)
        }

        // Restore element-scoped state
        context.pdf.style = scope.style
        context.pdf.layout.box.llx = scope.llx
        context.pdf.layout.box.urx = scope.urx
        context.pdf.mode.preserveWhitespace = scope.preserveWhitespace
        context.link.currentURL = scope.linkURL
        context.link.currentInternalId = scope.internalLinkId
    }

    // MARK: - Style Scope

    public static func _pushStyle(_ context: inout Self) {
        if record(.pushStyle, context: &context) { return }
        context.styleScopeStack.append(Style.Snapshot(from: context))
        // Clear so inner scopes don't consume the parent's break flags.
        context.forcePageBreakAfter = false
        context.avoidPageBreakAfter = false
        context.avoidPageBreakInside = false
    }

    public static func _popStyle(_ context: inout Self) {
        if record(.popStyle, context: &context) { return }

        // Apply bottom padding and margin before restoring
        if let paddingBottom = context.pdf.padding.bottom, paddingBottom > .zero {
            context.pdf.advance(paddingBottom)
        }
        if let marginBottom = context.pdf.margin.bottom, marginBottom > .zero {
            context.pdf.advance(marginBottom)
        }

        // Handle force page break set in THIS scope only.
        if context.forcePageBreakAfter {
            context.pdf.flush.inline()
            context.pdf.page.new()
            context.forcePageBreakAfter = false
        }

        // Restore saved state, then restore parent's break flags.
        if let snapshot = context.styleScopeStack.popLast() {
            snapshot.restore(to: &context)
            context.forcePageBreakAfter = snapshot.forcePageBreakAfter
            context.avoidPageBreakAfter = snapshot.avoidPageBreakAfter
            context.avoidPageBreakInside = snapshot.avoidPageBreakInside
        }
    }
}

// MARK: - Box Model Application

extension PDF.HTML.Context {
    /// Apply CSS box model (margins, padding, explicit width) to layout.
    ///
    /// Called after style modifiers set margin/padding properties.
    mutating func applyBoxModel() {
        if let marginTop = pdf.margin.top, marginTop > .zero {
            pdf.advance(marginTop)
        }
        if let marginLeft = pdf.margin.left {
            pdf.layout.box.llx = pdf.layout.box.llx + marginLeft
        }
        if let marginRight = pdf.margin.right {
            pdf.layout.box.urx = pdf.layout.box.urx - marginRight
        }
        if let paddingTop = pdf.padding.top, paddingTop > .zero {
            pdf.advance(paddingTop)
        }
        if let paddingLeft = pdf.padding.left {
            pdf.layout.box.llx = pdf.layout.box.llx + paddingLeft
        }
        if let paddingRight = pdf.padding.right {
            pdf.layout.box.urx = pdf.layout.box.urx - paddingRight
        }
        if let explicitWidth = pdf.constraint.width {
            pdf.layout.box.urx = pdf.layout.box.llx + explicitWidth
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
            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
            let spacing = (context.configuration.defaultFontSize * context.configuration.horizontalGapEm).height
            context.pdf.advance(spacing)
            let layoutBox = context.pdf.layout.box
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
            let tableStartY = context.pdf.layout.box.lly
            let availableWidth = context.pdf.layout.box.width
            let cellPadding = context.configuration.table.cell.padding
            let defaultRowHeight = context.pdf.style.line.height + cellPadding.height * 2
            let tableX = context.pdf.layout.box.llx
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
            context.table?.tableStartY = tableStartY
            context.table?.currentFragmentStartY = tableStartY
            context.table?.currentFragmentEndY = tableStartY
            context.resetMarginCollapsing()

            // γ-slot drain: Border-family CSS modifiers that fired before
            // `_pushElement("table", …)` (when `context.table == nil`) stashed
            // their target values here; apply them now that the table context
            // exists, then clear the slots.
            if let pendingColor = context.pendingTableBorderColor {
                context.table?.borderColor = pendingColor
                context.pendingTableBorderColor = nil
            }
            if let pendingWidth = context.pendingTableBorderWidth {
                context.table?.borderWidth = pendingWidth
                context.pendingTableBorderWidth = nil
            }

        case "thead":
            context.with(\.table) { tc in
                tc.header.startCapturing()
            }

        case "tbody", "tfoot":
            break // Pass-through

        case "tr":
            if var tableCtx = context.table {
                let rowHeight = context.pdf.style.line.height + tableCtx.cell.padding.height * 2

                // Ensure room for this row; page-break if needed
                if context.pdf.page.exceeds(adding: rowHeight) {
                    // Draw fragment borders for rows already on this page
                    if tableCtx.totalRowsRendered > 0 {
                        HTML.Element.Tag<Never>.drawFragmentRightAndBottomBorders(
                            tableCtx: tableCtx,
                            fragmentStartY: tableCtx.currentFragmentStartY,
                            fragmentEndY: tableCtx.currentFragmentEndY,
                            context: &context
                        )
                    }

                    context.pdf.flush.text()
                    context.pdf.page.new()

                    // Update fragment tracking for new page
                    let newY = context.pdf.layout.box.lly
                    tableCtx.currentFragmentStartY = newY
                    tableCtx.currentFragmentEndY = newY
                }

                tableCtx.currentColumn = 0
                tableCtx.maxCellHeightInCurrentRow = PDF.UserSpace.Height(0)
                tableCtx.pendingCellBorders = []
                tableCtx.bounds = PDF.UserSpace.Rectangle(
                    x: tableCtx.bounds.llx,
                    y: context.pdf.layout.box.lly,
                    width: tableCtx.bounds.width,
                    height: rowHeight
                )

                if !tableCtx.columnsInitialized {
                    // Start recording first-row commands for column measurement
                    tableCtx.recording = .init(savedY: context.pdf.layout.box.lly)
                }

                context.table = tableCtx
            }

        case "td", "th":
            if var tableCtx = context.table, tableCtx.columnsInitialized {
                // Skip columns occupied by rowspan from previous rows
                tableCtx.advanceToNextAvailableColumn()

                let column = tableCtx.currentColumn
                let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
                let rowspan = context.attributes["rowspan"].flatMap { Int($0) } ?? 1

                // Mark grid for multi-row spanning
                if rowspan > 1 {
                    tableCtx.spans.mark(
                        fromRow: tableCtx.totalRowsRendered,
                        column: column,
                        rowspan: rowspan,
                        colspan: colspan,
                        columnCount: tableCtx.columnCount
                    )
                }

                context.table = tableCtx

                if column < tableCtx.columnCount {
                    let cellX = tableCtx.xForColumn(column)
                    let cellWidth = tableCtx.widthForColumns(column, count: colspan)
                    let cellPadding = tableCtx.cell.padding
                    let contentX = cellX + cellPadding.width
                    let contentWidth = cellWidth - cellPadding.width * 2
                    let contentY = tableCtx.bounds.lly + cellPadding.height
                    let contentHeight = tableCtx.bounds.height - cellPadding.height * 2
                    // Save layout box (restored in popElement)
                    context.pdf.layout.box = PDF.UserSpace.Rectangle(
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
                context.pdf.layout.box.llx = context.pdf.layout.box.llx + indent
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
            let markerX = context.pdf.layout.box.llx - markerWidth - markerGap
            context.pdf.list.marker = (marker: marker, x: markerX)

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
            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
            _ = context.pdf.list.stack.popLast()
            // Restore the pending margin saved during push
            context.pendingBottomMargin = scope.savedPendingMargin

        case "li":
            // Flush inline runs BEFORE clearing marker — otherwise the marker
            // is consumed by emitLine during flush, but already nil.
            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
            context.pdf.list.marker = nil

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
        let yPosition = context.pdf.layout.box.lly

        // Start capturing text for this heading (finalized in popBlockElement)
        context.section.activeHeading = .init(
            level: level,
            pageNumber: pageNumber,
            yPosition: yPosition
        )
    }
}

// MARK: - Table First-Row Measurement

extension PDF.HTML.Context {
    /// Finalize first-row measurement: compute column widths and replay recorded commands.
    private static func finalizeFirstRow(
        _ recording: Table.Recording,
        context: inout PDF.HTML.Context
    ) {
        guard var tableCtx = context.table, recording.columnCount > 0 else { return }

        // Weighted column-width allocation. Per-cell %-hints (from
        // `<td>.css.width(.percent(N))`) are recorded into
        // `recording.columnWidthWeights` keyed by column index; columns without
        // hints get a uniform weight (100/n). All weights are normalized to
        // sum to `bounds.width`. When no hints are present (every column gets
        // uniformWeight), this degrades to the prior `equalWidth` behavior.
        let n = recording.columnCount
        let totalWidth = tableCtx.bounds.width
        let uniformWeight = 100.0 / Double(n)
        var weights: [Double] = []
        weights.reserveCapacity(n)
        var weightSum = 0.0
        for i in 0..<n {
            let w = recording.columnWidthWeights[i] ?? uniformWeight
            weights.append(w)
            weightSum += w
        }
        tableCtx.columnWidths = weights.map { w in
            totalWidth / Dimension_Primitives.Scale(weightSum / w)
        }
        tableCtx.columnsInitialized = true
        tableCtx.spans.preallocate(rows: 64, columns: recording.columnCount)

        // Reset row state for replay
        tableCtx.currentColumn = 0
        tableCtx.maxCellHeightInCurrentRow = .init(0)
        tableCtx.pendingCellBorders = []
        context.table = tableCtx

        // Restore Y position (content will re-render at correct position)
        context.pdf.layout.box.lly = recording.savedY

        // Replay all recorded commands — cells now position correctly
        replay(recording.commands, context: &context)
    }

    /// Replay recorded rendering commands.
    private static func replay(
        _ commands: [Table.Recording.Command],
        context: inout PDF.HTML.Context
    ) {
        for command in commands {
            switch command {
            case .text(let content):
                context.text(content)
            case .lineBreak:
                context.lineBreak()
            case .thematicBreak:
                context.thematicBreak()
            case .image(let source, let alt):
                context.image(source: source, alt: alt)
            case .pageBreak:
                context.pageBreak()
            case .setAttribute(let name, let value):
                context.set(attribute: name, value)
            case .addClass(let name):
                context.add(class: name)
            case .writeRaw(let bytes):
                context.write(raw: bytes)
            case .inlineStyle(let property):
                _ = context.apply(inlineStyle: property)
            case .pushBlock(let role, let style):
                _pushBlock(&context, role: role, style: style)
            case .popBlock:
                _popBlock(&context)
            case .pushInline(let role, let style):
                _pushInline(&context, role: role, style: style)
            case .popInline:
                _popInline(&context)
            case .pushList(let kind, let start):
                _pushList(&context, kind: kind, start: start)
            case .popList:
                _popList(&context)
            case .pushItem:
                _pushItem(&context)
            case .popItem:
                _popItem(&context)
            case .pushLink(let destination):
                _pushLink(&context, destination: destination)
            case .popLink:
                _popLink(&context)
            case .pushAttributes:
                _pushAttributes(&context)
            case .popAttributes:
                _popAttributes(&context)
            case .pushElement(let tagName, let isBlock, let isVoid, let isPreElement):
                _pushElement(&context, tagName: tagName, isBlock: isBlock, isVoid: isVoid, isPreElement: isPreElement)
            case .popElement(let isBlock):
                _popElement(&context, isBlock: isBlock)
            case .pushStyle:
                _pushStyle(&context)
            case .popStyle:
                _popStyle(&context)
            }
        }
    }
}

// MARK: - Table Row/Cell Pop Helpers

extension PDF.HTML.Context {
    /// Finalize a table row: compute row height, draw borders, advance Y.
    private static func popTableRow(context: inout PDF.HTML.Context) {
        guard var tableCtx = context.table else { return }

        if context.pdf.inline.hasRuns {
            context.pdf.flush.inline()
        }

        let minRowHeight = context.pdf.style.line.height + tableCtx.cell.padding.height * 2
        let actualRowHeight = tableCtx.maxCellHeightInCurrentRow > minRowHeight
            ? tableCtx.maxCellHeightInCurrentRow
            : minRowHeight

        // Draw cell borders with correct row height
        let rowStartY = tableCtx.bounds.lly
        let rowEndY = rowStartY + actualRowHeight
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

        // Draw left border extensions for columns occupied by rowspan from previous rows
        let currentRow = tableCtx.totalRowsRendered
        let borderColor = tableCtx.borderColor
        let borderWidth = tableCtx.borderWidth.width
        for col in 0..<tableCtx.columnCount {
            if let span = tableCtx.spans.span(atRow: currentRow, column: col),
               col == span.originColumn {
                // Draw left border for the spanning cell's column at this row's height
                let cellX = tableCtx.xForColumn(col)
                context.pdf.emit.line(
                    from: PDF.UserSpace.Coordinate(x: cellX, y: rowStartY),
                    to: PDF.UserSpace.Coordinate(x: cellX, y: rowEndY),
                    color: borderColor,
                    width: borderWidth
                )
            }
        }

        // Update row heights
        tableCtx.rowHeights.append(actualRowHeight)

        // Advance past this row
        context.pdf.layout.box.lly = rowEndY
        tableCtx.tableEndY = rowEndY
        tableCtx.currentFragmentEndY = rowEndY
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
        if context.pdf.inline.hasRuns {
            context.pdf.flush.inline()
        }

        let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
        let rowspan = context.attributes["rowspan"].flatMap { Int($0) } ?? 1
        let textAlignment = context.pdf.style.textAlign

        // Compute actual cell content height (content Y advance + bottom padding)
        let cellContentHeight: PDF.UserSpace.Height
        if let tableCtx = context.table {
            cellContentHeight = (context.pdf.layout.box.lly - tableCtx.bounds.lly)
                .retag(Extent.Y<UserSpace>.self) + tableCtx.cell.padding.height
        } else {
            cellContentHeight = .init(0)
        }

        context.with(\.table) { tc in
            // Track max cell height for row height computation
            if rowspan == 1 && cellContentHeight > tc.maxCellHeightInCurrentRow {
                tc.maxCellHeightInCurrentRow = cellContentHeight
            }

            tc.pendingCellBorders.append(.init(
                column: tc.currentColumn,
                colspan: colspan,
                rowspan: rowspan,
                isHeader: isHeader,
                textAlignment: textAlignment
            ))
            tc.currentColumn += colspan
        }
    }
}
