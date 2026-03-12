// PDF.HTML.swift
// Namespace and helpers for HTML to PDF rendering

import CSS_Standard
import Dictionary_Primitives
import HTML_Renderable
import PDF_Rendering
import PDF_Standard
import Rendering_Primitives
import Stack_Primitives
import W3C_CSS_Shared

extension PDF {
    /// Namespace for HTML to PDF rendering
    public enum HTML {}
}

// MARK: - Shared Rendering Infrastructure

extension PDF.HTML {
    /// Create a rendering context from configuration with all defaults applied.
    static func prepareContext(
        configuration: PDF.HTML.Configuration
    ) -> PDF.HTML.Context {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )
        pdfContext.style.font = configuration.defaultFont
        pdfContext.style.fontSize = configuration.defaultFontSize
        pdfContext.style.color = configuration.defaultColor
        pdfContext.style.lineHeight = Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))
        return PDF.HTML.Context(pdf: pdfContext, configuration: configuration)
    }

    /// Result of rendering HTML to PDF, including collected metadata for outlines.
    public struct RenderResult: Sendable {
        /// The rendered PDF pages
        public let pages: [PDF.Page]
        /// Collected headings for outline/bookmark generation
        public let headings: [Context.HeadingEntry]
        /// Named destinations for internal links
        public let namedDestinations: [String: Context.DestinationInfo]
    }

    /// Finalize rendering: flush deferred content, resolve internal links, return result.
    static func finalizeRendering(
        context: inout PDF.HTML.Context
    ) -> RenderResult {
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }
        context.pdf.flushInlineRuns()

        let resolvedPages = PDF.Context.resolveInternalLinks(
            pages: context.pdf.pages,
            pendingLinks: context.pdf.pendingInternalLinks,
            namedDestinations: context.namedDestinations.mapValues { dest in
                (pageNumber: dest.pageNumber, yPosition: dest.yPosition)
            }
        )
        return RenderResult(
            pages: resolvedPages,
            headings: context.collectedHeadings,
            namedDestinations: context.namedDestinations
        )
    }
}

// MARK: - Entry Points

extension PDF.HTML {
    /// Render HTML content to PDF pages using static dispatch.
    public static func pages<H: PDF.HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> [PDF.Page] {
        var context = prepareContext(configuration: configuration)
        H._render(html(), context: &context)
        return finalizeRendering(context: &context).pages
    }

    /// Render HTML content to PDF pages with collected metadata using static dispatch.
    public static func render<H: PDF.HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> RenderResult {
        var context = prepareContext(configuration: configuration)
        H._render(html(), context: &context)
        return finalizeRendering(context: &context)
    }

    /// Render any HTML.View to PDF with collected metadata using dynamic dispatch.
    @_disfavoredOverload
    public static func render<H: HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> RenderResult {
        var context = prepareContext(configuration: configuration)
        renderHTMLView(html(), context: &context)
        return finalizeRendering(context: &context)
    }

    /// Render any HTML.View to PDF pages using dynamic dispatch.
    @_disfavoredOverload
    public static func pages<H: HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> [PDF.Page] {
        var context = prepareContext(configuration: configuration)
        renderHTMLView(html(), context: &context)
        return finalizeRendering(context: &context).pages
    }
}

// MARK: - Two-Pass Rendering with Headers/Footers

extension PDF.HTML {
    /// Render HTML content to PDF with running headers and footers.
    ///
    /// Uses two-pass rendering to provide accurate page numbers ("Page X of Y"):
    /// - Pass 1: Render content to determine total page count
    /// - Pass 2: Re-render with headers and footers on each page
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering (must include header.height/footer.height)
    ///   - header: Builder that creates header content for each page
    ///   - footer: Builder that creates footer content for each page
    ///   - content: The main HTML content to render
    /// - Returns: Array of PDF pages with headers and footers
    public static func pages<Content: PDF.HTML.View, Header: HTML.View, Footer: HTML.View>(
        configuration: PDF.HTML.Configuration,
        @HTML.Builder header: @escaping (PageInfo) -> Header,
        @HTML.Builder footer: @escaping (PageInfo) -> Footer,
        @HTML.Builder content: () -> Content
    ) -> [PDF.Page] {
        // Adjust margins to account for header/footer space
        let adjustedMargins = PDF.UserSpace.EdgeInsets(
            top: configuration.margins.top + configuration.header.height,
            leading: configuration.margins.leading,
            bottom: configuration.margins.bottom + configuration.footer.height,
            trailing: configuration.margins.trailing
        )

        // PASS 1: Render content to get page count and section info
        var pass1Config = configuration
        pass1Config.margins = adjustedMargins

        var pass1Context = prepareContext(configuration: pass1Config)
        let contentView = content()
        Content._render(contentView, context: &pass1Context)

        if let deferred = pass1Context.deferredKeepWithNextRender {
            pass1Context.deferredKeepWithNextRender = nil
            deferred.render(&pass1Context)
        }
        pass1Context.pdf.flushInlineRuns()

        let totalPages = pass1Context.pdf.pages.count
        let pageSectionTitles = pass1Context.pageSectionTitles
        let collectedHeadings = pass1Context.collectedHeadings

        // PASS 2: Render again with headers and footers
        // For each page, we render: header area, content area, footer area
        var finalPages: [PDF.Page] = []

        for pageNumber in 1...totalPages {
            let pageInfo = PageInfo(
                pageNumber: pageNumber,
                totalPages: totalPages,
                sectionTitle: pageSectionTitles[pageNumber],
                documentTitle: configuration.documentTitle,
                date: configuration.documentDate
            )

            // Create a single-page context for header
            var headerContext = PDF.Context(
                mediaBox: configuration.mediaBox,
                margins: PDF.UserSpace.EdgeInsets(
                    top: configuration.margins.top,
                    leading: configuration.margins.leading,
                    bottom: configuration.paperSize.height - configuration.margins.top - configuration.header.height,
                    trailing: configuration.margins.trailing
                )
            )
            headerContext.style = pass1Context.pdf.style

            var headerHTMLContext = PDF.HTML.Context(pdf: headerContext, configuration: configuration)
            renderHTMLView(header(pageInfo), context: &headerHTMLContext)
            headerHTMLContext.pdf.flushInlineRuns()

            // Create a single-page context for footer
            var footerContext = PDF.Context(
                mediaBox: configuration.mediaBox,
                margins: PDF.UserSpace.EdgeInsets(
                    top: configuration.paperSize.height - configuration.margins.bottom - configuration.footer.height,
                    leading: configuration.margins.leading,
                    bottom: configuration.margins.bottom,
                    trailing: configuration.margins.trailing
                )
            )
            footerContext.style = pass1Context.pdf.style

            var footerHTMLContext = PDF.HTML.Context(pdf: footerContext, configuration: configuration)
            renderHTMLView(footer(pageInfo), context: &footerHTMLContext)
            footerHTMLContext.pdf.flushInlineRuns()

            // Combine: get content page, header content, footer content
            let contentPage = pass1Context.pdf.pages[pageNumber - 1]

            // Merge content streams: header + content + footer
            var mergedContents: [PDF.ContentStream] = []
            if let headerPage = headerHTMLContext.pdf.pages.first {
                mergedContents.append(contentsOf: headerPage.contents)
            }
            mergedContents.append(contentsOf: contentPage.contents)
            if let footerPage = footerHTMLContext.pdf.pages.first {
                mergedContents.append(contentsOf: footerPage.contents)
            }

            // Merge resources
            var mergedResources = contentPage.resources
            if let headerPage = headerHTMLContext.pdf.pages.first {
                for (name, font) in headerPage.resources.fonts {
                    mergedResources.fonts[name] = font
                }
            }
            if let footerPage = footerHTMLContext.pdf.pages.first {
                for (name, font) in footerPage.resources.fonts {
                    mergedResources.fonts[name] = font
                }
            }

            let mergedPage = PDF.Page(
                mediaBox: contentPage.mediaBox,
                contents: mergedContents,
                resources: mergedResources,
                annotations: contentPage.annotations
            )

            finalPages.append(mergedPage)
        }

        return finalPages
    }
}

extension PDF.HTML {
    /// Dynamic dispatch entry point for rendering any HTML.View to PDF.
    ///
    /// Dynamic dispatch entry point for rendering arbitrary HTML.View types.
    ///
    /// Delegates to `iterativeDispatch` — the worklist-based interpreter that
    /// replaces the former mutual recursion between `renderHTMLView` and
    /// `renderInnerContent`.
    public static func renderHTMLView(
        _ view: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        iterativeDispatch(view, context: &context)
    }

    // MARK: - Worklist Interpreter

    /// Defunctionalized dispatch continuations.
    ///
    /// Each case is an instruction to the dispatch loop. The rendering pipeline's
    /// recursive calls are replaced by work items on an explicit worklist,
    /// following the `Tree.N.forEachPreOrder` pattern from `swift-tree-primitives`:
    /// push children in reverse order onto a `Stack`, process iteratively.
    ///
    /// Style/attribute save/restore follows the `Tree.N.removeSubtree` pattern:
    /// push `.restoreStyle`/`.restoreAttributes` before `.render(content)`.
    /// LIFO ordering guarantees content renders first, then the restore fires —
    /// equivalent to `defer`.
    private enum Dispatch {
        /// Process a value through the type detection pipeline.
        ///
        /// Replaces recursive calls to `renderHTMLView` and `renderInnerContent`.
        case render(Any)

        /// Post-visit: restore style state after children have rendered.
        ///
        /// Equivalent of `defer { context.pdf.style = saved }` in the former
        /// `renderStyledViaMirror`. Pushed BEFORE `.render(content)` — LIFO
        /// ensures content renders first.
        case restoreStyle(ISO_32000.Context.Style.Resolved)

        /// Post-visit: restore attribute scope after children have rendered.
        ///
        /// Fixes a pre-existing bug where `renderAttributesViaMirror` discarded
        /// HTML attributes (href, id, colspan, rowspan) that `Tag._render` reads.
        /// Reproduces the static path's save/merge/render/restore semantics.
        case restoreAttributes(Dictionary<String, String>.Ordered)

        /// Post-visit: force a page break after content has rendered.
        ///
        /// Reproduces the static path's `forcePageBreakAfter` handling from
        /// `HTML.Styled._render` (line 190-193). The flag is set by
        /// `PageBreakAfter` / `BreakAfter` style modifiers via
        /// `applyStylePropertyViaMirror`, captured during Styled layer peeling,
        /// and deferred until after content renders via LIFO ordering.
        case forcePageBreak
    }

    /// Iterative dispatch loop for the dynamic rendering pipeline.
    ///
    /// Replaces the mutual recursion between `renderHTMLView` and
    /// `renderInnerContent` with a single `Stack<Dispatch>` worklist,
    /// following the `Tree.N.forEachPreOrder` pattern from `swift-tree-primitives`.
    ///
    /// ## What becomes iterative
    ///
    /// | Recursion axis | Mechanism |
    /// |---|---|
    /// | Custom view body chain (`A → A.body → B → B.body`) | `.render(body)` pushed, loop continues |
    /// | Tuple children | Children pushed as `.render` items (absorbs `renderTupleIteratively`) |
    /// | CSS wrapper unwrapping | Extract base, push `.render(base)` |
    /// | `_Attributes` wrapper unwrapping | Save/merge/push `.restoreAttributes` + `.render(content)` |
    /// | `_Conditional` case extraction | Extract active case, push `.render(case)` |
    /// | `Optional` unwrapping | Extract `.some` value, push `.render(someValue)` |
    /// | Styled layer peeling | Save style, peel layers, push `.restoreStyle` then `.render(unwrapped)` |
    ///
    /// ## What stays recursive (bounded)
    ///
    /// `Tag._render` and `_renderElementDynamically` are **terminal operations** from
    /// the worklist's perspective. They handle their own children with their own `defer`
    /// blocks. When they call `renderBlockDynamic` → `renderHTMLView`, a new worklist
    /// instance is created. This re-entry is bounded by HTML Tag element nesting depth,
    /// not by wrapper-chain depth or custom-view body expansion.
    private static func iterativeDispatch(
        _ initial: Any,
        context: inout PDF.HTML.Context
    ) {
        var worklist = Stack<Dispatch>()
        worklist.push(.render(initial))

        while let item = worklist.pop() {
            switch item {
            case .restoreStyle(let saved):
                context.pdf.style = saved

            case .restoreAttributes(let saved):
                context.attributes = saved

            case .forcePageBreak:
                context.pdf.flushInlineRuns()
                context.pdf.startNewPage()

            case .render(let value):
                // Phase 0: Tuple — push children (absorbs renderTupleIteratively)
                if let tuple = value as? any Rendering._TupleMarker {
                    var elements: [Any] = []
                    tuple._collectElements(into: &elements)
                    // Push reversed for left-to-right processing (LIFO)
                    for element in elements.reversed() {
                        worklist.push(.render(element))
                    }
                    continue
                }

                // Phase 1: Mirror-based wrapper detection
                //
                // Mirror is allocated in this scope and freed at the end of
                // the switch case — before the next iteration. This replaces
                // the @inline(never) extraction functions (_renderWrapperIfDetected,
                // _renderInnerWrapperIfDetected) which existed solely to free
                // Mirror stack space before recursive calls.
                let mirror = Mirror(reflecting: value)

                if isStyledType(mirror) {
                    let savedStyle = context.pdf.style

                    // Peel consecutive Styled layers iteratively
                    var current = value
                    while true {
                        let m = Mirror(reflecting: current)
                        guard isStyledType(m) else { break }

                        var content: Any?
                        var property: Any?
                        for child in m.children {
                            switch child.label {
                            case "content": content = child.value
                            case "property": property = child.value
                            default: break
                            }
                        }

                        if let prop = property {
                            applyStylePropertyViaMirror(prop, context: &context)
                        }

                        guard let c = content else { break }
                        current = c
                    }

                    // Capture and reset break flags set by style modifiers
                    let shouldForcePageBreakAfter = context.forcePageBreakAfter
                    context.forcePageBreakAfter = false

                    // Post-visit: push in LIFO order —
                    // restore runs last, page break fires after content, content renders first
                    worklist.push(.restoreStyle(savedStyle))
                    if shouldForcePageBreakAfter {
                        worklist.push(.forcePageBreak)
                    }
                    worklist.push(.render(current))
                    continue
                }

                if isCSSWrapperType(mirror) {
                    for child in mirror.children {
                        if child.label == "base" {
                            worklist.push(.render(child.value))
                            break
                        }
                    }
                    continue
                }

                if isAttributesType(mirror) {
                    let savedAttributes = context.attributes

                    // Peel consecutive _Attributes layers iteratively,
                    // merging attributes at each layer. Reproduces the
                    // static path's save/merge/render/restore semantics.
                    var current = value
                    while true {
                        let m = Mirror(reflecting: current)
                        guard isAttributesType(m) else { break }

                        var contentValue: Any?
                        for child in m.children {
                            if child.label == "attributes",
                               let attrs = child.value as? [String: String] {
                                context.attributes.merge.keep.last(
                                    attrs.lazy.map { ($0.key, $0.value) }
                                )
                            }
                            if child.label == "content" {
                                contentValue = child.value
                            }
                        }

                        guard let c = contentValue else { break }
                        current = c
                    }

                    // Post-visit: push restore BEFORE content (LIFO)
                    worklist.push(.restoreAttributes(savedAttributes))
                    worklist.push(.render(current))
                    continue
                }

                if isConditionalType(mirror) {
                    for child in mirror.children {
                        if child.label == "first" || child.label == "second" {
                            worklist.push(.render(child.value))
                            break
                        }
                    }
                    continue
                }

                if isOptionalType(mirror) {
                    for child in mirror.children {
                        if child.label == "some" {
                            worklist.push(.render(child.value))
                            break
                        }
                    }
                    continue // .none → nothing pushed → nothing rendered
                }

                // Phase 2: as? casts (safe — wrappers filtered by Phase 1)
                //
                // These are terminal operations — they call _render directly.

                if let str = value as? String {
                    String._render(str, context: &context)
                    continue
                }

                if let anyView = value as? any _AnyViewContent {
                    anyView._renderAnyViewDynamically(context: &context)
                    continue
                }

                if let pdfView = value as? any PDF.HTML.View {
                    func render<V: PDF.HTML.View>(_ v: V) {
                        V._render(v, context: &context)
                    }
                    render(pdfView)
                    continue
                }

                if let element = value as? any _HTMLElementContent {
                    element._renderElementDynamically(context: &context)
                    continue
                }

                if value is any _HTMLRawContent {
                    continue
                }

                if let optional = value as? any _OptionalContent {
                    optional._renderOptionalDynamically(context: &context)
                    continue
                }

                if let conditional = value as? any _ConditionalContent {
                    conditional._renderConditionalDynamically(context: &context)
                    continue
                }

                if let array = value as? any _ArrayContent {
                    array._renderArrayDynamically(context: &context)
                    continue
                }

                // Fallback: custom HTML.View — push body (LOOP, not recurse)
                if let htmlView = value as? any HTML.View {
                    func pushBody<V: HTML.View>(_ v: V) {
                        worklist.push(.render(v.body as Any))
                    }
                    pushBody(htmlView)
                    continue
                }
            }
        }
    }

    // MARK: - Protocol-Based Styled Rendering (Static Dispatch Path)

    /// Render HTML.Styled content by flattening consecutive styled layers iteratively.
    ///
    /// This avoids stack overflow from deeply nested HTML.Styled wrappers (common in VStack
    /// and other components that chain CSS properties like `.css.alignItems().display().flexDirection()`).
    ///
    /// Instead of:
    /// ```
    /// Styled1._render -> renderHTMLView(Styled2) -> Styled2._render -> renderHTMLView(Styled3) -> ...
    /// ```
    ///
    /// We iterate through all nested Styled layers, apply styles, then render the innermost content:
    /// ```
    /// flatten: [Styled1, Styled2, Styled3, ...]
    /// apply all styles
    /// render innermost content
    /// ```
    static func renderFlattenedStyledContent(
        _ initialStyled: any _HTMLStyledContent,
        context: inout PDF.HTML.Context
    ) {
        context.withSavedStyleState { context in
            // Collect all consecutive HTML.Styled layers (avoid existential boxing by only casting to _HTMLStyledContent)
            var styledLayers: [any _HTMLStyledContent] = [initialStyled]

            // Flatten: iterate through nested HTML.Styled wrappers
            var current = initialStyled
            while let nested = current.wrappedStyledContent {
                styledLayers.append(nested)
                current = nested
            }

            // The last element in styledLayers has the innermost non-styled content
            let innermostStyled = styledLayers[styledLayers.count - 1]

            // Apply all styles in order (outermost to innermost)
            var shouldAvoidPageBreakAfter = false
            var shouldForcePageBreakAfter = false
            var shouldAvoidPageBreakInside = false

            for styled in styledLayers {
                let flags = styled.applyStyle(to: &context)
                // Accumulate break flags - any layer requesting it wins
                if flags.avoidBreakAfter { shouldAvoidPageBreakAfter = true }
                if flags.forceBreakAfter { shouldForcePageBreakAfter = true }
                if flags.avoidBreakInside { shouldAvoidPageBreakInside = true }
            }

            // Apply CSS Box Model
            // Margin: Apply vertical margins to Y position, horizontal margins to layout bounds
            if let marginTop = context.pdf.marginTop, marginTop.rawValue > 0 {
                context.pdf.advance(marginTop)
            }
            if let marginLeft = context.pdf.marginLeft {
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + marginLeft
            }
            if let marginRight = context.pdf.marginRight {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - marginRight
            }

            // Padding: Inset the layout box for content
            if let paddingTop = context.pdf.paddingTop, paddingTop.rawValue > 0 {
                context.pdf.advance(paddingTop)
            }
            if let paddingLeft = context.pdf.paddingLeft {
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + paddingLeft
            }
            if let paddingRight = context.pdf.paddingRight {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - paddingRight
            }

            // Explicit width/height constraints
            if let explicitWidth = context.pdf.explicitWidth {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.llx + explicitWidth
            }

            // Handle break-inside: avoid
            if shouldAvoidPageBreakInside {
                let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
                let configuration = context.configuration
                let pendingBottomMargin = context.pendingBottomMargin

                // Measure the element's total height
                let measuredHeight = context.pdf.measure { measureContext in
                    var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                    tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                    snapshot.restore(to: &tempHTMLContext.pdf)
                    innermostStyled.renderWrappedContent(context: &tempHTMLContext)
                    tempHTMLContext.pdf.flushInlineRuns()
                    measureContext.layoutBox.lly = tempHTMLContext.pdf.layoutBox.lly
                }

                // If it won't fit on current page but would fit on a fresh page, break before
                let pageContentHeight = context.configuration.content.height
                if context.pdf.wouldExceedPage(adding: measuredHeight) && measuredHeight <= pageContentHeight {
                    context.pdf.startNewPage()
                }
            }

            // Handle break-after: avoid (sticky header behavior)
            if shouldAvoidPageBreakAfter {
                let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
                let configuration = context.configuration
                let pendingBottomMargin = context.pendingBottomMargin

                let measuredHeight = context.pdf.measure { measureContext in
                    var tempHTMLContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
                    tempHTMLContext.pendingBottomMargin = pendingBottomMargin
                    snapshot.restore(to: &tempHTMLContext.pdf)
                    innermostStyled.renderWrappedContent(context: &tempHTMLContext)
                    tempHTMLContext.pdf.flushInlineRuns()
                    measureContext.layoutBox.lly = tempHTMLContext.pdf.layoutBox.lly
                }

                if let existingDeferred = context.deferredKeepWithNextRender {
                    let combinedHeight = existingDeferred.measuredHeight + measuredHeight
                    context.deferredKeepWithNextRender = PDF.HTML.Context.DeferredRender(
                        render: { ctx in
                            existingDeferred.render(&ctx)
                            snapshot.restore(to: &ctx.pdf)
                            innermostStyled.renderWrappedContent(context: &ctx)
                            ctx.pdf.flushInlineRuns()
                        },
                        measuredHeight: combinedHeight
                    )
                } else {
                    context.deferredKeepWithNextRender = PDF.HTML.Context.DeferredRender(
                        render: { ctx in
                            snapshot.restore(to: &ctx.pdf)
                            innermostStyled.renderWrappedContent(context: &ctx)
                            ctx.pdf.flushInlineRuns()
                        },
                        measuredHeight: measuredHeight
                    )
                }
            } else {
                // Normal rendering - render the innermost content
                innermostStyled.renderWrappedContent(context: &context)

                // Handle break-after: always/page
                if shouldForcePageBreakAfter {
                    context.pdf.flushInlineRuns()
                    context.pdf.startNewPage()
                }
            }

            // Apply bottom padding and margin after content renders
            if let paddingBottom = context.pdf.paddingBottom, paddingBottom.rawValue > 0 {
                context.pdf.advance(paddingBottom)
            }
            if let marginBottom = context.pdf.marginBottom, marginBottom.rawValue > 0 {
                context.pdf.advance(marginBottom)
            }
        }
    }
}

// MARK: - Mirror-Based Type Detection
//
// These predicates identify wrapper types by examining field names via Mirror,
// avoiding `as?` casts that crash on deeply nested generic types (SIGBUS in
// `swift_conformsToProtocolMaybeInstantiateSuperclasses`).
//
// Used by the worklist interpreter's Phase 1 to detect wrappers BEFORE
// Phase 2's `as?` casts.
//
// FRAGILITY WARNING: Depends on internal field names of types in
// swift-html-rendering. If those field names change, this code will break.

extension PDF.HTML {

    /// Detect `HTML.Styled<Content>` by checking for "content" and "property" fields.
    ///
    /// HTML.Styled wraps content with a CSS property for inline styling.
    /// Structure: `struct Styled<Content> { let content: Content; let property: P? }`
    ///
    /// - Note: HTML._Attributes also has "content" but uses "attributes" instead of "property"
    private static func isStyledType(_ mirror: Mirror) -> Bool {
        var hasContent = false
        var hasProperty = false
        for child in mirror.children {
            if child.label == "content" { hasContent = true }
            if child.label == "property" { hasProperty = true }
            if hasContent && hasProperty { return true }
        }
        return false
    }

    /// Detect `HTML.CSS<Base>` by checking for "base" field (without "renderFunction").
    ///
    /// HTML.CSS wraps content for CSS property chaining (`.css.display().flexDirection()`).
    /// Structure: `struct CSS<Base> { let base: Base }`
    ///
    /// - Note: HTML.AnyView also has "base" but additionally has "renderFunction",
    ///   so we exclude types that have both to avoid misidentification.
    private static func isCSSWrapperType(_ mirror: Mirror) -> Bool {
        var hasBase = false
        var hasRenderFunction = false
        for child in mirror.children {
            if child.label == "base" { hasBase = true }
            if child.label == "renderFunction" { hasRenderFunction = true }
        }
        return hasBase && !hasRenderFunction
    }

    /// Detect `HTML._Attributes<Content>` by checking for "content" and "attributes" fields.
    ///
    /// HTML._Attributes wraps content with HTML attributes (id, class, href, etc.).
    /// Structure: `struct _Attributes<Content> { let content: Content; var attributes: [...] }`
    ///
    /// - Note: HTML.Styled also has "content" but uses "property" instead of "attributes"
    private static func isAttributesType(_ mirror: Mirror) -> Bool {
        var hasContent = false
        var hasAttributes = false
        for child in mirror.children {
            if child.label == "content" { hasContent = true }
            if child.label == "attributes" { hasAttributes = true }
            if hasContent && hasAttributes { return true }
        }
        return false
    }

    /// Detect `_Conditional<First, Second>` by checking for enum display style
    /// and "first" or "second" case labels.
    ///
    /// _Conditional is an enum created by if/else in result builders.
    /// Structure: `enum _Conditional<First, Second> { case first(First); case second(Second) }`
    ///
    /// When branches contain deeply nested generic types (e.g., HTML.Element<TableRow<...>>),
    /// using `as?` casts to detect conditionals can crash with SIGBUS. Mirror-based detection
    /// avoids this by not triggering Swift's type metadata instantiation.
    private static func isConditionalType(_ mirror: Mirror) -> Bool {
        guard mirror.displayStyle == .enum else { return false }
        // Enum cases appear as children with labels "first" or "second"
        for child in mirror.children {
            if child.label == "first" || child.label == "second" {
                return true
            }
        }
        return false
    }

    /// Detect `Optional<Wrapped>` by checking for optional display style.
    ///
    /// Optional is created by `if` without `else` in result builders (buildOptional).
    /// Structure: `enum Optional<Wrapped> { case none; case some(Wrapped) }`
    ///
    /// When the wrapped type is deeply nested (e.g., Optional<TableRow<...>>),
    /// using `as?` casts can crash with SIGBUS. Mirror-based detection avoids this.
    private static func isOptionalType(_ mirror: Mirror) -> Bool {
        return mirror.displayStyle == .optional
    }

    /// Apply a CSS property value to the PDF context.
    ///
    /// Property types are simple value types (FontWeight, Color, Display, etc.),
    /// not deeply nested generic wrappers, so `as?` casts are safe.
    ///
    /// The property may be wrapped in Optional, so we unwrap that first via Mirror.
    private static func applyStylePropertyViaMirror(
        _ prop: Any,
        context: inout PDF.HTML.Context
    ) {
        let unwrapped: Any
        let propMirror = Mirror(reflecting: prop)
        if propMirror.displayStyle == .optional {
            if let firstChild = propMirror.children.first {
                unwrapped = firstChild.value
            } else {
                return
            }
        } else {
            unwrapped = prop
        }

        if let modifier = unwrapped as? any PDF.HTML.StyleModifier {
            modifier.apply(to: &context.pdf, configuration: context.configuration)
        }

        if let htmlModifier = unwrapped as? any PDF.HTML.HTMLContextStyleModifier {
            htmlModifier.apply(to: &context)
        }
    }

    /// Dynamic dispatch for type-erased values extracted from Mirror children.
    ///
    /// Delegates to `iterativeDispatch` — same loop, same dispatch logic.
    static func renderInnerContent(
        _ value: Any,
        context: inout PDF.HTML.Context
    ) {
        iterativeDispatch(value, context: &context)
    }
}

// MARK: - Dynamic Dispatch Support Protocols

/// Internal protocol to enable dynamic dispatch for _Tuple without variadic constraints.
///
/// This works around Swift's limitation where runtime existential casts (`as? any Protocol`)
/// don't work correctly for conditional conformances on variadic generics.
package protocol _TupleContent {
    /// Render each element of the tuple using dynamic dispatch.
    func _renderEachElementDynamically(context: inout PDF.HTML.Context)
    /// Collect each element of the tuple into a flat collection for iterative rendering.
    func _collectElements(into collection: inout [Any])
}

/// Marker protocol for HTML.Element.Tag dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `HTML.Element.Tag: PDF.HTML.View where Content: PDF.HTML.View`.
package protocol _HTMLElementContent {
    /// Render this element using dynamic dispatch for content.
    func _renderElementDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for HTML.Raw (renders as empty in PDF context).
///
/// Raw HTML content (like `<script>...</script>`) doesn't have a meaningful
/// PDF representation and is safely ignored during PDF rendering.
package protocol _HTMLRawContent {}

/// Marker protocol for HTML.Styled dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `HTML.Styled: PDF.HTML.View where Content: PDF.HTML.View`.
package protocol _HTMLStyledContent {
    /// Render this styled content using dynamic dispatch for the wrapped content.
    func _renderStyledDynamically(context: inout PDF.HTML.Context)

    /// The CSS property to apply (may be nil).
    var styledProperty: Any? { get }

    /// Apply this styled element's property to the context.
    /// Returns flags for break handling.
    func applyStyle(to context: inout PDF.HTML.Context) -> (avoidBreakAfter: Bool, forceBreakAfter: Bool, avoidBreakInside: Bool)

    /// Get the wrapped content as _HTMLStyledContent if it is one (avoids existential boxing).
    var wrappedStyledContent: (any _HTMLStyledContent)? { get }

    /// Render the wrapped content directly (avoids existential boxing of content).
    func renderWrappedContent(context: inout PDF.HTML.Context)
}

/// Marker protocol for _Conditional dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `_Conditional: PDF.HTML.View where First: PDF.HTML.View, Second: PDF.HTML.View`.
package protocol _ConditionalContent {
    /// Render the active branch of this conditional using dynamic dispatch.
    func _renderConditionalDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for _Array dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `_Array: PDF.HTML.View where Element: PDF.HTML.View`.
package protocol _ArrayContent {
    /// Render all elements in the array using dynamic dispatch.
    func _renderArrayDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for Optional dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `Optional: PDF.HTML.View where Wrapped: PDF.HTML.View`.
package protocol _OptionalContent {
    /// Render the optional's wrapped value if present, using dynamic dispatch.
    func _renderOptionalDynamically(context: inout PDF.HTML.Context)
}

// MARK: - Block and Inline Helpers

extension PDF.HTML {
    /// Render content as a block element (flushes inline runs before and after).
    @inlinable
    public static func renderBlock<C: PDF.HTML.View>(
        _ content: C?,
        context: inout PDF.HTML.Context,
        beforeSpacing: PDF.UserSpace.Height = .init(0),
        afterSpacing: PDF.UserSpace.Height = .init(0)
    ) {
        // Flush pending inline runs
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Add spacing before
        if beforeSpacing > .init(0) {
            context.pdf.advance(beforeSpacing)
        }

        // Render content
        if let content {
            C._render(content, context: &context)
        }

        // Flush inline runs from content
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Add spacing after
        if afterSpacing > .init(0) {
            context.pdf.advance(afterSpacing)
        }
    }

    /// Render content inline (no flush).
    @inlinable
    public static func renderInline<C: PDF.HTML.View>(
        _ content: C?,
        context: inout PDF.HTML.Context
    ) {
        if let content {
            C._render(content, context: &context)
        }
    }

    // MARK: - Dynamic Dispatch Helpers

    /// Dynamic dispatch version of renderBlock.
    ///
    /// Use this when the content type is only known to conform to `HTML.View`,
    /// not `PDF.HTML.View`. This enables rendering of content that uses custom
    /// view types without explicit PDF conformance.
    public static func renderBlockDynamic(
        _ content: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        // Flush pending inline runs
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Render content using dynamic dispatch
        renderHTMLView(content, context: &context)

        // Flush inline runs from content
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }
    }

    /// Dynamic dispatch version of renderInline.
    ///
    /// Use this when the content type is only known to conform to `HTML.View`,
    /// not `PDF.HTML.View`. This enables rendering of content that uses custom
    /// view types without explicit PDF conformance.
    public static func renderInlineDynamic(
        _ content: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        renderHTMLView(content, context: &context)
    }
}
