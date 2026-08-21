import Byte_Primitives
import Dictionary_Ordered_Primitive
import Dictionary_Ordered_Primitives
import HTML_Rendering_Core
import Layout_Primitives
import PDF_Rendering
import Render_Primitives

extension PDF.HTML.Context {

    public mutating func text(_ content: borrowing String) {

        if insideStyleBlock {
            currentStyleBlockBuffer += copy content
            return
        }
        if insideTitleBlock {
            return
        }

        let copy = copy content

        if table?.recording != nil {
            table!.recording!.commands.append(.text(copy))

            if table!.recording!.currentCellColumn != nil {
                let runs = PDF.Context.Text.Run.runsWithSymbolSupport(
                    text: copy,
                    font: pdf.style.font,
                    fontSize: pdf.style.fontSize,
                    color: pdf.style.color
                )
                let spaceWidth = pdf.style.font.winAnsi.width(
                    of: [Byte(UInt8.ascii.space)],
                    atSize: pdf.style.fontSize
                )
                var maxToken: PDF.UserSpace.Width = .init(0)
                var lineWidth: PDF.UserSpace.Width = .init(0)
                for run in runs {
                    var tokenStart = 0
                    for (i, byte) in run.bytes.enumerated() {
                        if byte.underlying.ascii.isWhitespace {
                            if i > tokenStart {
                                let tokenBytes = Array(run.bytes[tokenStart..<i])
                                let w = run.font.winAnsi.width(of: tokenBytes, atSize: run.fontSize)
                                if w > maxToken { maxToken = w }
                                lineWidth += w
                            }
                            lineWidth += spaceWidth
                            tokenStart = i + 1
                        }
                    }
                    if tokenStart < run.bytes.count {
                        let tokenBytes = Array(run.bytes[tokenStart...])
                        let w = run.font.winAnsi.width(of: tokenBytes, atSize: run.fontSize)
                        if w > maxToken { maxToken = w }
                        lineWidth += w
                    }
                }
                if maxToken > table!.recording!.currentCellMinWidth {
                    table!.recording!.currentCellMinWidth = maxToken
                }

                table!.recording!.currentLineWidth += lineWidth
            }
            return
        }

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

    public mutating func lineBreak() {
        if table?.recording != nil {
            table!.recording!.commands.append(.lineBreak)

            if table!.recording!.currentCellColumn != nil {
                let lw = table!.recording!.currentLineWidth
                if lw > table!.recording!.currentCellMaxWidth {
                    table!.recording!.currentCellMaxWidth = lw
                }
                table!.recording!.currentLineWidth = .init(0)
            }
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

    public mutating func image(source: String, alt: String) {
        if table?.recording != nil {
            table!.recording!.commands.append(.image(source: source, alt: alt))
            return
        }
        pdf.flush.inline()
        let run = PDF.Context.Text.Run(
            text: alt.isEmpty ? "[image]" : "[\(alt)]",
            font: pdf.style.font.italic,
            fontSize: pdf.style.fontSize,
            color: .gray(0.5)
        )
        pdf.append(inline: run)
        pdf.flush.inline()
    }

    public mutating func pageBreak() {
        if table?.recording != nil {
            table!.recording!.commands.append(.pageBreak)
            return
        }
        pdf.flush.inline()
        pdf.flush.text()
        pdf.page.new()
    }

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
            attributes[name] = nil
        }
    }

    public mutating func add(class name: String) {
        if table?.recording != nil {
            table!.recording!.commands.append(.addClass(name))
            return
        }

    }

    public mutating func write(raw bytes: [UInt8]) {
        if table?.recording != nil {
            table!.recording!.commands.append(.writeRaw(bytes))
            return
        }

    }

    public mutating func register(
        style declaration: String,
        atRule: String?,
        selector: String?,
        pseudo: String?
    ) -> String? {

        nil
    }

    public mutating func apply(inlineStyle property: Any) -> Bool {
        if table?.recording != nil {
            table!.recording!.commands.append(.inlineStyle(property))

            if table!.recording!.elementDepth == 1 {
                Self.captureCellWidthHint(from: property, into: &table!.recording!)
                Self.captureCellPaddingHint(from: property, into: &table!.recording!)
            }
            return true
        }

        let unwrapped: Any
        let mirror = Mirror(reflecting: property)
        if mirror.displayStyle == .optional {
            guard let first = mirror.children.first else { return false }
            unwrapped = first.value
        } else {
            unwrapped = property
        }

        var handled = false

        if unwrapped is W3C_CSS_BoxModel.Width {

            pendingExplicitWidth = true
        }

        if let modifier = unwrapped as? any ISO_32000.HTML.Style.Modifier {

            if pdf.inline.hasRuns {
                pdf.flush.inline()
            }
            modifier.apply(to: &pdf, configuration: configuration)
            handled = true
        }

        if let htmlModifier = unwrapped as? any ISO_32000.HTML.Style.Context.Modifier {
            htmlModifier.apply(to: &self)
            handled = true
        }

        if handled {
            applyBoxModel()
        }

        return handled
    }

    @inline(always)
    private static func record(
        _ command: Table.Recording.Command,
        context: inout Self
    ) -> Bool {
        guard context.table?.recording != nil else { return false }
        context.table!.recording!.commands.append(command)
        return true
    }

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

    private static func captureCellPaddingHint(
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
        if let r = unwrapped as? W3C_CSS_BoxModel.PaddingRight {
            recording.pendingCellHorizontalPadding += pxValue(of: r)
        } else if let l = unwrapped as? W3C_CSS_BoxModel.PaddingLeft {
            recording.pendingCellHorizontalPadding += pxValue(of: l)
        }
    }

    private static func pxValue(of right: W3C_CSS_BoxModel.PaddingRight) -> Double {
        guard case .lengthPercentage(let lp) = right else { return 0 }
        return pxValue(of: lp)
    }
    private static func pxValue(of left: W3C_CSS_BoxModel.PaddingLeft) -> Double {
        guard case .lengthPercentage(let lp) = left else { return 0 }
        return pxValue(of: lp)
    }
    private static func pxValue(of lp: W3C_CSS_Values.LengthPercentage) -> Double {
        guard case .length(let length) = lp else { return 0 }
        if case .length(let v, .px) = length { return v }
        return 0
    }

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

    public static func _pushAttributes(_ context: inout Self) {
        if record(.pushAttributes, context: &context) { return }
        context.elementStack.append(
            Element.Scope(
                tagName: "_attributes",
                isBlock: false,
                style: context.pdf.style,
                llx: context.pdf.layout.box.llx,
                urx: context.pdf.layout.box.urx,
                preserveWhitespace: context.pdf.mode.preserveWhitespace,
                noWrap: context.pdf.mode.noWrap,
                linkURL: context.link.currentURL,
                internalLinkId: context.link.currentInternalId,
                savedTable: nil,
                savedPendingMargin: context.pendingBottomMargin,
                isVoid: false
            )
        )
    }

    public static func _popAttributes(_ context: inout Self) {
        if record(.popAttributes, context: &context) { return }
        if let scope = context.elementStack.popLast(), scope.tagName == "_attributes" {
            context.attributes = .init()
        }
    }

    public static func _pushElement(
        _ context: inout Self,
        tagName: String,
        isBlock: Bool,
        isVoid: Bool,
        isPreElement: Bool
    ) {

        if context.table?.recording != nil {
            context.table!.recording!.commands.append(
                .pushElement(
                    tagName: tagName,
                    isBlock: isBlock,
                    isVoid: isVoid,
                    isPreElement: isPreElement
                )
            )

            let isTransparent =
                isVoid
                || tagName == "thead"
                || tagName == "tbody"
                || tagName == "tfoot"

            context.table!.recording!.pushedIsVoid.append(isTransparent)
            if !isTransparent {

                if context.table!.recording!.elementDepth == 0 && tagName == "tr" {
                    context.table!.recording!.cellsPushedInCurrentRow = 0
                }

                if context.table!.recording!.elementDepth == 1
                    && (tagName == "td" || tagName == "th")
                {
                    let columnIdx = context.table!.recording!.cellsPushedInCurrentRow
                    if let weight = context.table!.recording!.pendingCellWidthPercent {
                        context.table!.recording!.columnWidthWeights[columnIdx] = weight
                        context.table!.recording!.pendingCellWidthPercent = nil
                    }
                    let colspan = context.table!.recording!.pendingColspan
                    context.table!.recording!.pendingColspan = 1
                    context.table!.recording!.cellsPushedInCurrentRow += colspan

                    if context.table!.recording!.topLevelRowIndex == 0 {
                        context.table!.recording!.columnCount = max(
                            context.table!.recording!.columnCount,
                            context.table!.recording!.cellsPushedInCurrentRow
                        )
                    }
                    context.table!.recording!.currentCellColumn = columnIdx
                    context.table!.recording!.currentCellMinWidth = .init(0)
                    context.table!.recording!.currentCellMaxWidth = .init(0)
                    context.table!.recording!.currentLineWidth = .init(0)
                    context.table!.recording!.currentCellPadding =
                        context.table!.recording!.pendingCellHorizontalPadding
                    context.table!.recording!.pendingCellHorizontalPadding = 0
                }

                if context.table!.recording!.elementDepth > 1
                    && tagName == "tr"
                    && context.table!.recording!.currentCellColumn != nil
                {
                    let lw = context.table!.recording!.currentLineWidth
                    if lw > context.table!.recording!.currentCellMaxWidth {
                        context.table!.recording!.currentCellMaxWidth = lw
                    }
                    context.table!.recording!.currentLineWidth = .init(0)
                }
                context.table!.recording!.elementDepth += 1
            }
            return
        }

        if isVoid {
            let voidScope = Element.Scope(
                tagName: tagName,
                isBlock: isBlock,
                style: context.pdf.style,
                llx: context.pdf.layout.box.llx,
                urx: context.pdf.layout.box.urx,
                preserveWhitespace: context.pdf.mode.preserveWhitespace,
                noWrap: context.pdf.mode.noWrap,
                linkURL: context.link.currentURL,
                internalLinkId: context.link.currentInternalId,
                savedTable: nil,
                savedPendingMargin: context.pendingBottomMargin,
                isVoid: true
            )
            context.elementStack.append(voidScope)
            handleVoidElement(tagName, context: &context)

            context.pendingExplicitWidth = false
            return
        }

        let pendingBorderTop = context.pendingSideBorderTop
        let pendingBorderRight = context.pendingSideBorderRight
        let pendingBorderBottom = context.pendingSideBorderBottom
        let pendingBorderLeft = context.pendingSideBorderLeft
        context.pendingSideBorderTop = nil
        context.pendingSideBorderRight = nil
        context.pendingSideBorderBottom = nil
        context.pendingSideBorderLeft = nil
        var scope = Element.Scope(
            tagName: tagName,
            isBlock: isBlock,
            style: context.pdf.style,
            llx: context.pdf.layout.box.llx,
            urx: context.pdf.layout.box.urx,
            preserveWhitespace: context.pdf.mode.preserveWhitespace,
            noWrap: context.pdf.mode.noWrap,
            linkURL: context.link.currentURL,
            internalLinkId: context.link.currentInternalId,
            savedTable: tagName == "table" ? context.table : nil,
            savedPendingMargin: context.pendingBottomMargin,
            isVoid: false
        )
        scope.pendingBorderTop = pendingBorderTop
        scope.pendingBorderRight = pendingBorderRight
        scope.pendingBorderBottom = pendingBorderBottom
        scope.pendingBorderLeft = pendingBorderLeft
        context.elementStack.append(scope)

        let loweredTag = tagName.lowercased()
        switch loweredTag {
        case "style":
            context.insideStyleBlock = true
            context.currentStyleBlockBuffer = ""

        case "title":
            context.insideTitleBlock = true

        default:
            break
        }

        HTML.Tag.Element<Never>.applyTagStyle(tagName, context: &context)

        context.applyParsedCSSRules(forTagName: loweredTag)

        if tagName == "a" {
            if let href = context.attributes["href"] {
                if href.hasPrefix("#") {
                    context.link.currentInternalId = String(href.dropFirst())
                } else {
                    context.link.currentURL = href
                }
            }
        }

        if let elementId = context.attributes["id"], !elementId.isEmpty {
            let pageNumber = context.pdf.completedPages.count + 1
            let yPosition = context.pdf.layout.box.lly
            context.link.destinations[elementId] = Self.Link.Destination(
                pageNumber: pageNumber,
                yPosition: yPosition
            )
        }

        if isBlock {
            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }

            let isNestedList = (tagName == "ul" || tagName == "ol") && context.pdf.list.depth > 0
            let userOverrodeMargin =
                context.pdf.margin.top != nil
                || context.pdf.margin.bottom != nil
            if !isNestedList,
                !userOverrodeMargin,
                let margins = HTML.Tag.Element<Never>.blockMargins(
                    for: tagName,
                    configuration: context.configuration
                )
            {
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

            if let headingLevel = HTML.Tag.Element<Never>.headingLevel(for: tagName) {
                pushHeading(level: headingLevel, tagName: tagName, context: &context)
            }

            pushBlockElement(tagName, context: &context)
        } else {

            pushInlineElement(tagName, context: &context)
        }

        context.pendingExplicitWidth = false
    }

    public static func _popElement(_ context: inout Self, isBlock: Bool) {

        if context.table?.recording != nil {
            let wasVoid = context.table!.recording!.pushedIsVoid.popLast() ?? false
            if wasVoid {
                context.table!.recording!.commands.append(.popElement(isBlock: isBlock))
                return
            }
            context.table!.recording!.elementDepth -= 1
            if context.table!.recording!.elementDepth < 0 {

                let recording = context.table!.recording!
                context.table!.recording = nil
                finalizeFirstRow(recording, context: &context)

            } else {

                if context.table!.recording!.elementDepth == 1,
                    let col = context.table!.recording!.currentCellColumn
                {

                    let lw = context.table!.recording!.currentLineWidth
                    if lw > context.table!.recording!.currentCellMaxWidth {
                        context.table!.recording!.currentCellMaxWidth = lw
                    }
                    context.table!.recording!.currentLineWidth = .init(0)

                    let pad = context.table!.recording!.currentCellPadding
                    if pad > 0 {
                        context.table!.recording!.currentCellMaxWidth +=
                            PDF.UserSpace.Width(pad)
                        context.table!.recording!.currentCellMinWidth +=
                            PDF.UserSpace.Width(pad)
                    }
                    let r = context.table!.recording!
                    let prevMin = r.columnMinContentWidths[col] ?? .init(0)
                    let prevMax = r.columnMaxContentWidths[col] ?? .init(0)
                    if r.currentCellMinWidth > prevMin {
                        context.table!.recording!.columnMinContentWidths[col] =
                            r.currentCellMinWidth
                    }
                    if r.currentCellMaxWidth > prevMax {
                        context.table!.recording!.columnMaxContentWidths[col] =
                            r.currentCellMaxWidth
                    }
                    context.table!.recording!.currentCellColumn = nil
                }

                if context.table!.recording!.elementDepth == 0 {

                    context.table!.recording!.topLevelRowIndex += 1
                }
                context.table!.recording!.commands.append(.popElement(isBlock: isBlock))
                return
            }
        }

        guard let scope = context.elementStack.popLast() else { return }

        switch scope.tagName.lowercased() {
        case "style":
            if context.insideStyleBlock {
                let buffer = context.currentStyleBlockBuffer
                context.collectedStyleBlocks.append(buffer)
                let parsed = PDF.HTML.CSS.Stylesheet.Parser.parse(buffer)
                context.parsedStylesheet.rules.append(contentsOf: parsed.rules)
                context.currentStyleBlockBuffer = ""
                context.insideStyleBlock = false
            }

        case "title":
            context.insideTitleBlock = false

        default:
            break
        }

        if scope.isVoid { return }

        if isBlock {
            popBlockElement(scope, context: &context)

            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
        } else {
            popInlineElement(scope.tagName, context: &context)
        }

        context.pdf.style = scope.style
        context.pdf.layout.box.llx = scope.llx
        context.pdf.layout.box.urx = scope.urx
        context.pdf.mode.preserveWhitespace = scope.preserveWhitespace
        context.pdf.mode.noWrap = scope.noWrap
        context.link.currentURL = scope.linkURL
        context.link.currentInternalId = scope.internalLinkId
    }

    public static func _pushStyle(_ context: inout Self) {
        if record(.pushStyle, context: &context) { return }
        context.styleScopeStack.append(Style.Snapshot(from: context))

        context.forcePageBreakAfter = false
        context.avoidPageBreakAfter = false
        context.avoidPageBreakInside = false
    }

    public static func _popStyle(_ context: inout Self) {
        if record(.popStyle, context: &context) { return }

        if let paddingBottom = context.pdf.padding.bottom, paddingBottom > .zero {
            context.pdf.advance(paddingBottom)
        }
        if let marginBottom = context.pdf.margin.bottom, marginBottom > .zero {
            context.pdf.advance(marginBottom)
        }

        if context.forcePageBreakAfter {
            context.pdf.flush.inline()
            context.pdf.page.new()
            context.forcePageBreakAfter = false
        }

        if let snapshot = context.styleScopeStack.popLast() {
            snapshot.restore(to: &context)
            context.forcePageBreakAfter = snapshot.forcePageBreakAfter
            context.avoidPageBreakAfter = snapshot.avoidPageBreakAfter
            context.avoidPageBreakInside = snapshot.avoidPageBreakInside
        }
    }
}

extension PDF.HTML.Context {

    mutating func applyBoxModel() {
        if let marginTop = pdf.margin.top, marginTop > .zero {
            pdf.advance(marginTop)
        }
        if let marginLeft = pdf.margin.left {
            pdf.layout.box.llx += marginLeft
        }
        if let marginRight = pdf.margin.right {
            pdf.layout.box.urx -= marginRight
        }
        if let paddingTop = pdf.padding.top, paddingTop > .zero {
            pdf.advance(paddingTop)
        }
        if let paddingLeft = pdf.padding.left {
            pdf.layout.box.llx += paddingLeft
        }
        if let paddingRight = pdf.padding.right {
            pdf.layout.box.urx -= paddingRight
        }
        if let explicitWidth = pdf.constraint.width {
            pdf.layout.box.urx = pdf.layout.box.llx + explicitWidth

            pdf.constraint.width = nil
        }
        if pdf.constraint.height != nil {

            pdf.constraint.height = nil
        }
    }
}

extension PDF.HTML.Context {
    private static func handleVoidElement(
        _ tagName: String,
        context: inout PDF.HTML.Context
    ) {
        switch tagName {
        case "br":

            if context.pdf.inline.runs.isEmpty {
                context.pdf.advance.line()
            } else {
                context.pdf.flush.inline()
            }

        case "hr":
            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
            let spacing =
                (context.configuration.defaultFontSize * context.configuration.horizontalGapEm)
                .height
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

extension PDF.HTML.Context {

    private static func pushBlockElement(
        _ tagName: String,
        context: inout PDF.HTML.Context
    ) {
        switch tagName {

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
            context.table = Self.Table(
                bounds: tableBounds,
                columnWidths: [],
                rowHeights: [],
                cellPadding: cellPadding,
                borderColor: context.configuration.table.border.color,
                borderWidth: context.configuration.table.border.width,
                headerBackground: context.configuration.table.headerBackground,
                alternatingRowColor: context.configuration.table.alternatingRowColor
            )
            let explicit = context.pendingExplicitWidth
            context.table?.totalRowsRendered = 0
            context.table?.tableStartY = tableStartY
            context.table?.currentFragmentStartY = tableStartY
            context.table?.currentFragmentEndY = tableStartY
            context.table?.hasExplicitWidth = explicit

            if !context.table!.columnsInitialized {
                context.table?.recording = .init(savedY: tableStartY)
            }
            context.resetMarginCollapsing()

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
            break

        case "tr":
            if var tableCtx = context.table {
                let rowHeight = context.pdf.style.line.height + tableCtx.cell.padding.height * 2

                if context.pdf.page.exceeds(adding: rowHeight) {

                    if tableCtx.totalRowsRendered > 0 {
                        HTML.Tag.Element<Never>.drawFragmentRightAndBottomBorders(
                            tableCtx: tableCtx,
                            fragmentStartY: tableCtx.currentFragmentStartY,
                            fragmentEndY: tableCtx.currentFragmentEndY,
                            context: &context
                        )
                    }

                    context.pdf.flush.text()
                    context.pdf.page.new()

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

                context.table = tableCtx
            }

        case "td", "th":
            if var tableCtx = context.table, tableCtx.columnsInitialized {

                tableCtx.advanceToNextAvailableColumn()

                let column = tableCtx.currentColumn
                let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
                let rowspan = context.attributes["rowspan"].flatMap { Int($0) } ?? 1

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

                    context.pdf.layout.box = PDF.UserSpace.Rectangle(
                        x: contentX,
                        y: contentY,
                        width: contentWidth,
                        height: contentHeight
                    )
                    if tagName == "th" {
                        context.pdf.style.font = context.pdf.style.font.bold
                    }
                }
            }

        case "ol", "ul":
            if let listType = HTML.Tag.Element<Never>.listType(for: tagName) {
                context.pdf.push(list: listType)
                let indent = context.configuration.indent.list
                context.pdf.layout.box.llx += indent
                let savedPendingMargin = context.pendingBottomMargin
                context.pendingBottomMargin = .init(0)

                if let last = context.elementStack.popLast() {
                    context.elementStack.append(
                        Element.Scope(
                            tagName: last.tagName,
                            isBlock: last.isBlock,
                            style: last.style,
                            llx: last.llx,
                            urx: last.urx,
                            preserveWhitespace: last.preserveWhitespace,
                            noWrap: last.noWrap,
                            linkURL: last.linkURL,
                            internalLinkId: last.internalLinkId,
                            savedTable: last.savedTable,
                            savedPendingMargin: savedPendingMargin,
                            isVoid: last.isVoid
                        )
                    )
                }
            }

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
            let markerGap = (context.pdf.style.fontSize * context.configuration.horizontalGapEm)
                .width
            let markerX = context.pdf.layout.box.llx - markerWidth - markerGap
            context.pdf.list.marker = (marker: marker, x: markerX)

        default:
            break
        }
    }

    private static func popBlockElement(
        _ scope: Element.Scope,
        context: inout PDF.HTML.Context
    ) {
        switch scope.tagName {
        case "table":

            if let tc = context.table {
                HTML.Tag.Element<Never>.drawTableRightAndBottomBorders(
                    tableCtx: tc,
                    context: &context
                )
            }

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
            popTableRow(scope: scope, context: &context)

        case "td", "th":
            popTableCell(scope: scope, isHeader: scope.tagName == "th", context: &context)

        case "ol", "ul":
            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
            _ = context.pdf.list.stack.popLast()

            context.pendingBottomMargin = scope.savedPendingMargin

        case "li":

            if context.pdf.inline.hasRuns {
                context.pdf.flush.inline()
            }
            context.pdf.list.marker = nil

        default:

            if let heading = context.section.activeHeading,
                HTML.Tag.Element<Never>.headingLevel(for: scope.tagName) != nil
            {
                let text = String(
                    heading.text.drop(while: { $0 == " " }).reversed().drop(while: { $0 == " " })
                        .reversed()
                )
                if !text.isEmpty {
                    context.section.headings.append(
                        .init(
                            level: heading.level,
                            text: text,
                            pageNumber: heading.pageNumber,
                            yPosition: heading.yPosition
                        )
                    )
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

extension PDF.HTML.Context {
    private static func pushInlineElement(
        _ tagName: String,
        context: inout PDF.HTML.Context
    ) {
        if tagName == "q" {

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

        context.section.activeHeading = .init(
            level: level,
            pageNumber: pageNumber,
            yPosition: yPosition
        )
    }
}

extension PDF.HTML.Context {

    private static func finalizeFirstRow(
        _ recording: Table.Recording,
        context: inout PDF.HTML.Context
    ) {
        guard var tableCtx = context.table, recording.columnCount > 0 else { return }

        let n = recording.columnCount
        let totalWidth = tableCtx.bounds.width
        let uniformPercentHint = 100.0 / Double(n)

        var measuredSum = 0.0
        var measuredCount = 0
        (0..<n).forEach { i in
            if let m = recording.columnMaxContentWidths[i], m.underlying > 0 {
                measuredSum += m.underlying
                measuredCount += 1
            }
        }
        let avgMeasured = measuredCount > 0 ? measuredSum / Double(measuredCount) : 0.0

        let hasPercentHints = !recording.columnWidthWeights.isEmpty
        let useShrinkToFit =
            !tableCtx.hasExplicitWidth
            && !hasPercentHints
            && measuredCount > 0
        var columnWidths: [PDF.UserSpace.Width] = []
        columnWidths.reserveCapacity(n)
        if useShrinkToFit {
            var rawWidths: [Double] = []
            var rawSum = 0.0
            (0..<n).forEach { i in
                let raw = recording.columnMaxContentWidths[i]?.underlying ?? avgMeasured
                rawWidths.append(raw)
                rawSum += raw
            }
            if rawSum > 0 && rawSum <= totalWidth.underlying {
                for raw in rawWidths {
                    columnWidths.append(.init(raw))
                }
            } else {
                for raw in rawWidths {
                    let w = totalWidth * Dimension_Primitives.Scale(raw / max(rawSum, .ulpOfOne))
                    columnWidths.append(w)
                }
            }
        } else {

            var weights: [Double] = []
            weights.reserveCapacity(n)
            var weightSum = 0.0
            (0..<n).forEach { i in
                let pct = recording.columnWidthWeights[i] ?? uniformPercentHint
                let measured = recording.columnMaxContentWidths[i]?.underlying ?? 0
                let content = measured > 0 ? measured : avgMeasured
                let w = pct + content
                weights.append(w)
                weightSum += w
            }
            (0..<n).forEach { i in
                let w =
                    totalWidth * Dimension_Primitives.Scale(weights[i] / max(weightSum, .ulpOfOne))
                columnWidths.append(w)
            }
        }

        (0..<n).forEach { i in
            if let minC = recording.columnMinContentWidths[i], columnWidths[i] < minC {
                columnWidths[i] = minC
            }
        }
        tableCtx.columnWidths = columnWidths
        tableCtx.columnsInitialized = true
        tableCtx.spans.preallocate(rows: 64, columns: recording.columnCount)

        tableCtx.currentColumn = 0
        tableCtx.maxCellHeightInCurrentRow = .init(0)
        tableCtx.pendingCellBorders = []
        context.table = tableCtx

        context.pdf.layout.box.lly = recording.savedY

        replay(recording.commands, context: &context)
    }

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
                _pushElement(
                    &context,
                    tagName: tagName,
                    isBlock: isBlock,
                    isVoid: isVoid,
                    isPreElement: isPreElement
                )

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

extension PDF.HTML.Context {

    private static func popTableRow(
        scope: Element.Scope,
        context: inout PDF.HTML.Context
    ) {
        guard var tableCtx = context.table else { return }

        if context.pdf.inline.hasRuns {
            context.pdf.flush.inline()
        }

        let minRowHeight = context.pdf.style.line.height + tableCtx.cell.padding.height * 2
        let actualRowHeight =
            tableCtx.maxCellHeightInCurrentRow > minRowHeight
            ? tableCtx.maxCellHeightInCurrentRow
            : minRowHeight

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
            HTML.Tag.Element<Never>.drawCellBorder(
                bounds: cellBounds,
                tableCtx: tableCtx,
                context: &context
            )

            drawScopeSideBorders(
                top: pending.pendingBorderTop,
                right: pending.pendingBorderRight,
                bottom: pending.pendingBorderBottom,
                left: pending.pendingBorderLeft,
                bounds: cellBounds,
                context: &context
            )
        }

        let rowBounds = PDF.UserSpace.Rectangle(
            x: tableCtx.bounds.llx,
            y: rowStartY,
            width: tableCtx.bounds.width,
            height: actualRowHeight
        )
        drawScopeSideBorders(
            top: scope.pendingBorderTop,
            right: scope.pendingBorderRight,
            bottom: scope.pendingBorderBottom,
            left: scope.pendingBorderLeft,
            bounds: rowBounds,
            context: &context
        )

        let currentRow = tableCtx.totalRowsRendered
        let borderColor = tableCtx.borderColor
        let borderWidth = tableCtx.borderWidth.width
        (0..<tableCtx.columnCount).forEach { col in
            if let span = tableCtx.spans.span(atRow: currentRow, column: col),
                col == span.originColumn
            {

                let cellX = tableCtx.xForColumn(col)
                context.pdf.emit.line(
                    from: PDF.UserSpace.Coordinate(x: cellX, y: rowStartY),
                    to: PDF.UserSpace.Coordinate(x: cellX, y: rowEndY),
                    color: borderColor,
                    width: borderWidth
                )
            }
        }

        tableCtx.rowHeights.append(actualRowHeight)

        let pageBrokeInRow = context.pdf.layout.box.lly < rowStartY
        let effectiveRowEndY = pageBrokeInRow ? context.pdf.layout.box.lly : rowEndY
        context.pdf.layout.box.lly = effectiveRowEndY
        tableCtx.tableEndY = effectiveRowEndY
        tableCtx.currentFragmentEndY = effectiveRowEndY
        tableCtx.totalRowsRendered += 1
        tableCtx.currentColumn = 0
        tableCtx.pendingCellBorders = []
        context.table = tableCtx
    }

    private static func popTableCell(
        scope: Element.Scope,
        isHeader: Bool,
        context: inout PDF.HTML.Context
    ) {
        if context.pdf.inline.hasRuns {
            context.pdf.flush.inline()
        }

        let colspan = context.attributes["colspan"].flatMap { Int($0) } ?? 1
        let rowspan = context.attributes["rowspan"].flatMap { Int($0) } ?? 1
        let textAlignment = context.pdf.style.textAlign

        let cellContentHeight: PDF.UserSpace.Height
        if let tableCtx = context.table {
            cellContentHeight =
                (context.pdf.layout.box.lly - tableCtx.bounds.lly)
                .retag(Extent.Y<UserSpace>.self) + tableCtx.cell.padding.height
        } else {
            cellContentHeight = .init(0)
        }

        context.with(\.table) { tc in

            if rowspan == 1 && cellContentHeight > tc.maxCellHeightInCurrentRow {
                tc.maxCellHeightInCurrentRow = cellContentHeight
            }

            tc.pendingCellBorders.append(
                .init(
                    column: tc.currentColumn,
                    colspan: colspan,
                    rowspan: rowspan,
                    isHeader: isHeader,
                    textAlignment: textAlignment,
                    pendingBorderTop: scope.pendingBorderTop,
                    pendingBorderRight: scope.pendingBorderRight,
                    pendingBorderBottom: scope.pendingBorderBottom,
                    pendingBorderLeft: scope.pendingBorderLeft
                )
            )
            tc.currentColumn += colspan
        }
    }

    private static func drawScopeSideBorders(
        top: Element.Scope.PendingSideBorder?,
        right: Element.Scope.PendingSideBorder?,
        bottom: Element.Scope.PendingSideBorder?,
        left: Element.Scope.PendingSideBorder?,
        bounds: PDF.UserSpace.Rectangle,
        context: inout PDF.HTML.Context
    ) {
        if let top {
            HTML.Tag.Element<Never>.drawHorizontalBorder(
                from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
                to: PDF.UserSpace.Coordinate(x: bounds.urx, y: bounds.lly),
                color: top.color,
                width: top.width.width,
                style: top.style,
                context: &context
            )
        }
        if let bottom {
            HTML.Tag.Element<Never>.drawHorizontalBorder(
                from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.ury),
                to: PDF.UserSpace.Coordinate(x: bounds.urx, y: bounds.ury),
                color: bottom.color,
                width: bottom.width.width,
                style: bottom.style,
                context: &context
            )
        }
        if let left {
            HTML.Tag.Element<Never>.drawVerticalBorder(
                from: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.lly),
                to: PDF.UserSpace.Coordinate(x: bounds.llx, y: bounds.ury),
                color: left.color,
                width: left.width.width,
                style: left.style,
                context: &context
            )
        }
        if let right {
            HTML.Tag.Element<Never>.drawVerticalBorder(
                from: PDF.UserSpace.Coordinate(x: bounds.urx, y: bounds.lly),
                to: PDF.UserSpace.Coordinate(x: bounds.urx, y: bounds.ury),
                color: right.color,
                width: right.width.width,
                style: right.style,
                context: &context
            )
        }
    }
}
