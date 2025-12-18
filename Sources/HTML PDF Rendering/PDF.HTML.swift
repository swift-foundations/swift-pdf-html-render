// PDF.HTML.swift
// Namespace and helpers for HTML to PDF rendering

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import PDF_Standard
import Rendering
import W3C_CSS_Shared

extension PDF {
    /// Namespace for HTML to PDF rendering
    public enum HTML {}
}

// MARK: - Style Modifier Protocol


// MARK: - Main Entry Point

extension PDF.HTML {
    /// Render HTML content to PDF pages using static dispatch.
    ///
    /// This is the preferred entry point when the HTML type is known to conform
    /// to `PDF.HTML.View`, enabling full static dispatch throughout rendering.
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering
    ///   - html: The HTML view to render
    /// - Returns: Array of PDF pages
    public static func pages<H: PDF.HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> [PDF.Page] {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )
        
        // Apply configuration defaults
        pdfContext.style.font = configuration.defaultFont
        pdfContext.style.fontSize = configuration.defaultFontSize
        pdfContext.style.color = configuration.defaultColor
        // Resolve CSS line-height to concrete multiplier for PDF rendering
        pdfContext.style.lineHeight = Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))
        
        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)
        
        // Render HTML to PDF using static dispatch
        H._render(html(), context: &context)
        
        // Handle any remaining deferred content (e.g., sticky header at end of document)
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }
        
        // Flush any remaining inline runs
        context.pdf.flushInlineRuns()

        // Resolve pending internal links and return pages
        let rawPages = context.pdf.pages
        return PDF.Context.resolveInternalLinks(
            pages: rawPages,
            pendingLinks: context.pdf.pendingInternalLinks,
            namedDestinations: context.namedDestinations.mapValues { dest in
                (pageNumber: dest.pageNumber, yPosition: dest.yPosition)
            }
        )
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

    /// Render HTML content to PDF pages with collected metadata.
    ///
    /// This variant returns additional metadata collected during rendering,
    /// including headings (for bookmarks) and named destinations (for internal links).
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering
    ///   - html: The HTML view to render
    /// - Returns: RenderResult containing pages and collected metadata
    public static func render<H: PDF.HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> RenderResult {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )

        // Apply configuration defaults
        pdfContext.style.font = configuration.defaultFont
        pdfContext.style.fontSize = configuration.defaultFontSize
        pdfContext.style.color = configuration.defaultColor
        pdfContext.style.lineHeight = Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))

        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)

        // Render HTML to PDF using static dispatch
        H._render(html(), context: &context)

        // Handle any remaining deferred content
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }

        // Flush any remaining inline runs
        context.pdf.flushInlineRuns()

        // Resolve pending internal links
        let rawPages = context.pdf.pages
        let resolvedPages = PDF.Context.resolveInternalLinks(
            pages: rawPages,
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

    /// Render any HTML.View to PDF with collected metadata using dynamic dispatch.
    ///
    /// This overload accepts any `HTML.View` and uses runtime checks to dispatch
    /// to the appropriate rendering implementation. Use this when working with
    /// custom views that haven't explicitly declared `PDF.HTML.View` conformance.
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering
    ///   - html: The HTML view to render
    /// - Returns: RenderResult containing pages and collected metadata
    @_disfavoredOverload
    public static func render<H: HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> RenderResult {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )

        // Apply configuration defaults
        pdfContext.style.font = configuration.defaultFont
        pdfContext.style.fontSize = configuration.defaultFontSize
        pdfContext.style.color = configuration.defaultColor
        pdfContext.style.lineHeight = Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))

        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)

        // Render using dynamic dispatch
        renderHTMLView(html(), context: &context)

        // Handle any remaining deferred content
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }

        // Flush any remaining inline runs
        context.pdf.flushInlineRuns()

        // Resolve pending internal links
        let rawPages = context.pdf.pages
        let resolvedPages = PDF.Context.resolveInternalLinks(
            pages: rawPages,
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

extension PDF.HTML {
    /// Render any HTML.View to PDF using dynamic dispatch.
    ///
    /// This overload accepts any `HTML.View` and uses runtime checks to dispatch
    /// to the appropriate `PDF.HTML.View._render` implementation. Use this when
    /// working with custom views that haven't explicitly declared `PDF.HTML.View`
    /// conformance.
    ///
    /// - Parameters:
    ///   - configuration: Configuration for the rendering
    ///   - html: The HTML view to render
    /// - Returns: Array of PDF pages
    @_disfavoredOverload
    public static func pages<H: HTML.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> [PDF.Page] {
        var pdfContext = PDF.Context(
            mediaBox: configuration.mediaBox,
            margins: configuration.margins
        )
        
        // Apply configuration defaults
        pdfContext.style.font = configuration.defaultFont
        pdfContext.style.fontSize = configuration.defaultFontSize
        pdfContext.style.color = configuration.defaultColor
        // Resolve CSS line-height to concrete multiplier for PDF rendering
        pdfContext.style.lineHeight = Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))
        
        // Create combined context
        var context = PDF.HTML.Context(pdf: pdfContext, configuration: configuration)
        
        // Render using dynamic dispatch
        renderHTMLView(html(), context: &context)
        
        // Handle any remaining deferred content (e.g., sticky header at end of document)
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }
        
        // Flush any remaining inline runs
        context.pdf.flushInlineRuns()

        // Resolve pending internal links and return pages
        let rawPages = context.pdf.pages
        return PDF.Context.resolveInternalLinks(
            pages: rawPages,
            pendingLinks: context.pdf.pendingInternalLinks,
            namedDestinations: context.namedDestinations.mapValues { dest in
                (pageNumber: dest.pageNumber, yPosition: dest.yPosition)
            }
        )
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
        let pass1Config = PDF.HTML.Configuration(
            paperSize: configuration.paperSize,
            margins: adjustedMargins,
            header: configuration.header,
            footer: configuration.footer,
            documentTitle: configuration.documentTitle,
            documentDate: configuration.documentDate,
            defaultFont: configuration.defaultFont,
            defaultFontSize: configuration.defaultFontSize,
            defaultColor: configuration.defaultColor,
            lineHeight: configuration.lineHeight,
            paragraphSpacing: configuration.paragraphSpacing,
            headingSpacing: configuration.headingSpacing,
            typography: configuration.typography,
            indent: configuration.indent,
            horizontalGapEm: configuration.horizontalGapEm,
            deferredHeaderThreshold: configuration.deferredHeaderThreshold,
            table: configuration.table
        )

        var pass1PdfContext = PDF.Context(
            mediaBox: pass1Config.mediaBox,
            margins: adjustedMargins
        )
        pass1PdfContext.style.font = pass1Config.defaultFont
        pass1PdfContext.style.fontSize = pass1Config.defaultFontSize
        pass1PdfContext.style.color = pass1Config.defaultColor
        pass1PdfContext.style.lineHeight = Scale(pass1Config.resolveLineHeight(
            for: pass1Config.defaultFont,
            fontSize: pass1Config.defaultFontSize
        ))

        var pass1Context = PDF.HTML.Context(pdf: pass1PdfContext, configuration: pass1Config)
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
            headerContext.style = pass1PdfContext.style

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
            footerContext.style = pass1PdfContext.style

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
    /// This function determines HOW to render an arbitrary HTML.View at runtime.
    /// It must handle the "wrapper type problem" where types like HTML.Styled,
    /// HTML.CSS, and HTML._Attributes create deeply nested generic types that
    /// crash Swift's runtime when we try to use `as?` casts on them.
    ///
    /// See the detailed explanation in "Mirror-Based Rendering" section below.
    ///
    /// - Important: This function MUST check for wrapper types via Mirror BEFORE
    ///   attempting any `as?` cast. The order of checks matters for correctness.
    public static func renderHTMLView(
        _ view: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        // ════════════════════════════════════════════════════════════════════════
        // PHASE 1: Mirror-based detection of wrapper types (MUST come first!)
        //
        // These types create deeply nested generics that crash on `as?` casts.
        // We detect them by examining field names via Mirror, which doesn't
        // trigger the problematic type metadata instantiation.
        // ════════════════════════════════════════════════════════════════════════

        let mirror = Mirror(reflecting: view)

        // HTML.Styled: wraps content with CSS property (.inlineStyle(...))
        // Identified by: "content" + "property" fields
        if isStyledType(mirror) {
            renderStyledViaMirror(view, context: &context)
            return
        }

        // HTML.CSS: wraps content for CSS chaining (.css.display().flex())
        // Identified by: "base" field (without "renderFunction")
        if isCSSWrapperType(mirror) {
            renderCSSWrapperViaMirror(mirror, context: &context)
            return
        }

        // HTML._Attributes: wraps content with HTML attributes (.attribute(...))
        // Identified by: "content" + "attributes" fields
        if isAttributesType(mirror) {
            renderAttributesViaMirror(mirror, context: &context)
            return
        }

        // _Conditional: if/else branches in result builders
        // Identified by: enum display style with "first" or "second" case
        // Must be detected via Mirror to avoid SIGBUS on deeply nested generic branches
        if isConditionalType(mirror) {
            renderConditionalViaMirror(mirror, context: &context)
            return
        }

        // Optional: if-without-else in result builders (buildOptional)
        // Identified by: optional display style
        // Must be detected via Mirror to avoid SIGBUS on deeply nested generic wrapped types
        if isOptionalType(mirror) {
            renderOptionalViaMirror(mirror, context: &context)
            return
        }

        // ════════════════════════════════════════════════════════════════════════
        // PHASE 2: Safe `as?` casts (only reached for non-wrapper types)
        //
        // At this point, we've confirmed the view is NOT a wrapper type, so it's
        // safe to use `as?` casts. These won't crash because the type isn't
        // deeply nested in wrapper generics.
        // ════════════════════════════════════════════════════════════════════════

        // Helper to invoke static dispatch once we have a PDF.HTML.View
        func renderPDFView<V: PDF.HTML.View>(_ v: V) {
            V._render(v, context: &context)
        }

        // 1. HTML.AnyView: type-erased wrapper - must handle before PDF.HTML.View
        //    check to avoid infinite recursion (AnyView conforms to PDF.HTML.View)
        if let anyView = view as? any _AnyViewContent {
            anyView._renderAnyViewDynamically(context: &context)
            return
        }

        // 2. PDF.HTML.View: types with explicit PDF rendering - use static dispatch
        if let pdfView = view as? any PDF.HTML.View {
            renderPDFView(pdfView)
            return
        }

        // 3-8. Types with conditional conformances that Swift can't verify at runtime.
        //      We use marker protocols (_TupleContent, etc.) that are always conformed
        //      to, enabling dynamic dispatch to the correct render implementation.

        if let tuple = view as? any _TupleContent {
            tuple._renderEachElementDynamically(context: &context)
            return
        }

        if let element = view as? any _HTMLElementContent {
            element._renderElementDynamically(context: &context)
            return
        }

        if view is any _HTMLRawContent {
            return // Raw HTML (scripts, etc.) has no PDF representation
        }

        if let optional = view as? any _OptionalContent {
            optional._renderOptionalDynamically(context: &context)
            return
        }

        if let conditional = view as? any _ConditionalContent {
            conditional._renderConditionalDynamically(context: &context)
            return
        }

        if let array = view as? any _ArrayContent {
            array._renderArrayDynamically(context: &context)
            return
        }

        // 9. Fallback: custom HTML.View types without explicit PDF conformance.
        //    Render their body, which will recursively call renderHTMLView.
        //
        //    ⚠️ This calls .body, which crashes for wrapper types with
        //    `var body: Never { fatalError(...) }`. Safe here because we already
        //    filtered out wrapper types in Phase 1.
        func renderBody<V: HTML.View>(_ v: V) {
            renderHTMLView(v.body, context: &context)
        }
        renderBody(view)
    }

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
        // Save current style state - we'll restore after all nested styles
        let savedStyle = context.pdf.style

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

        defer {
            // Restore style state after rendering content
            context.pdf.style = savedStyle
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
    }
}

// MARK: - Mirror-Based Rendering (Workaround for Swift Runtime Crash)
//
// ╔══════════════════════════════════════════════════════════════════════════════╗
// ║                           WHY THIS CODE EXISTS                               ║
// ╠══════════════════════════════════════════════════════════════════════════════╣
// ║                                                                              ║
// ║  THE PROBLEM:                                                                ║
// ║  ────────────                                                                ║
// ║  Swift's runtime crashes with EXC_BAD_ACCESS when performing `as?` casts    ║
// ║  on deeply nested generic types. This happens in the function               ║
// ║  `swift_conformsToProtocolMaybeInstantiateSuperclasses` when it tries to    ║
// ║  instantiate type metadata for types like:                                  ║
// ║                                                                              ║
// ║    HTML.Styled<HTML.Styled<HTML._Attributes<HTML._Attributes<               ║
// ║      HTML._Attributes<HTML._Attributes<HTML._Attributes<HTML._Attributes<   ║
// ║        HTML._Attributes<HTML._Attributes<HTML.Element.Tag<...>>>>>>>>>>     ║
// ║                                                                              ║
// ║  These deeply nested types are created naturally when chaining modifiers:   ║
// ║                                                                              ║
// ║    div { ... }                                                              ║
// ║      .inlineStyle(Color.red)        // Wraps in HTML.Styled                 ║
// ║      .inlineStyle(FontWeight.bold)  // Wraps again in HTML.Styled           ║
// ║      .attribute("id", "foo")        // Wraps in HTML._Attributes            ║
// ║      .attribute("class", "bar")     // Wraps again in HTML._Attributes      ║
// ║      .css.display(.flex)            // Wraps in HTML.CSS                    ║
// ║      ...                            // Each call adds another wrapper layer ║
// ║                                                                              ║
// ║  WHY STATIC DISPATCH WORKS (in swift-html-rendering):                       ║
// ║  ────────────────────────────────────────────────────────────────────────── ║
// ║  In swift-html-rendering, the compiler knows the exact type at compile      ║
// ║  time, so it can resolve the correct `_render` method statically:           ║
// ║                                                                              ║
// ║    extension HTML.Styled: HTML.View where Content: HTML.View {              ║
// ║      static func _render(_ view: Self, ...) {                               ║
// ║        Content._render(view.content, ...)  // Type known at compile time!   ║
// ║      }                                                                       ║
// ║    }                                                                         ║
// ║                                                                              ║
// ║  WHY DYNAMIC DISPATCH CRASHES (in swift-pdf-html-rendering):                ║
// ║  ────────────────────────────────────────────────────────────────────────── ║
// ║  Here, we receive `some HTML.View` and need to determine HOW to render it   ║
// ║  at runtime. Any `as?` cast triggers type metadata instantiation:           ║
// ║                                                                              ║
// ║    func renderHTMLView(_ view: some HTML.View, ...) {                       ║
// ║      if let styled = view as? any _HTMLStyledContent { ... }  // 💥 CRASH!  ║
// ║    }                                                                         ║
// ║                                                                              ║
// ║  THE SOLUTION:                                                              ║
// ║  ─────────────                                                              ║
// ║  Use Swift's Mirror API to inspect type structure by examining FIELD NAMES  ║
// ║  rather than checking protocol conformance. Mirror doesn't trigger the      ║
// ║  same metadata instantiation that causes the crash.                         ║
// ║                                                                              ║
// ║  We identify wrapper types by their unique field signatures:                ║
// ║    • HTML.Styled      → has "content" + "property" fields                   ║
// ║    • HTML.CSS         → has "base" field (no "renderFunction")              ║
// ║    • HTML._Attributes → has "content" + "attributes" fields                 ║
// ║                                                                              ║
// ║  IMPORTANT INVARIANTS:                                                      ║
// ║  ─────────────────────                                                      ║
// ║  1. ALWAYS check for wrapper types via Mirror BEFORE any `as?` cast         ║
// ║  2. Wrapper types can nest in ANY order (Styled→CSS→Attributes→Styled→...)  ║
// ║  3. Once we extract content via Mirror, check again - it might be wrapped!  ║
// ║  4. Only use `as?` on values AFTER confirming they're not wrapper types     ║
// ║  5. Property types (FontWeight, Color, etc.) are simple - safe to cast      ║
// ║                                                                              ║
// ║  FRAGILITY WARNING:                                                         ║
// ║  ──────────────────                                                         ║
// ║  This approach depends on the internal field names of types in              ║
// ║  swift-html-rendering. If those field names change, this code will break.   ║
// ║  There is no compile-time safety here - only runtime behavior.              ║
// ║                                                                              ║
// ╚══════════════════════════════════════════════════════════════════════════════╝

extension PDF.HTML {

    // ┌──────────────────────────────────────────────────────────────────────────┐
    // │                        TYPE DETECTION FUNCTIONS                          │
    // │                                                                          │
    // │  These functions identify wrapper types by examining their field names   │
    // │  via Mirror. This avoids triggering Swift's type metadata system.        │
    // └──────────────────────────────────────────────────────────────────────────┘

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

    // ┌──────────────────────────────────────────────────────────────────────────┐
    // │                      MIRROR-BASED RENDER FUNCTIONS                       │
    // │                                                                          │
    // │  These functions traverse wrapper types by extracting field values via   │
    // │  Mirror, then recursively processing the inner content.                  │
    // └──────────────────────────────────────────────────────────────────────────┘

    /// Render `HTML.Styled` content by iteratively unwrapping nested layers.
    ///
    /// Instead of recursively calling render functions (which would still build up
    /// call stack depth), we use a while loop to peel off Styled layers one at a time,
    /// applying each style property as we go.
    ///
    /// Flow:
    /// ```
    /// Styled<Styled<Styled<Element, A>, B>, C>
    ///   ↓ extract property C, apply it
    /// Styled<Styled<Element, A>, B>
    ///   ↓ extract property B, apply it
    /// Styled<Element, A>
    ///   ↓ extract property A, apply it
    /// Element
    ///   ↓ not a Styled type, call renderInnerContent()
    /// ```
    static func renderStyledViaMirror(
        _ value: Any,
        context: inout PDF.HTML.Context
    ) {
        // Save style state - we restore after rendering so styles don't leak
        // to sibling elements (CSS properties should only affect descendants)
        let savedStyle = context.pdf.style
        defer { context.pdf.style = savedStyle }

        // Iteratively unwrap nested HTML.Styled layers (avoids deep recursion)
        var current: Any = value
        while true {
            let mirror = Mirror(reflecting: current)

            // If this is still a Styled wrapper, peel off one layer
            if isStyledType(mirror) {
                var content: Any?
                var property: Any?

                // Extract the content and property fields from the struct
                for child in mirror.children {
                    switch child.label {
                    case "content": content = child.value
                    case "property": property = child.value
                    default: break
                    }
                }

                // Apply the style property to the PDF context.
                // Property types (FontWeight, Color, Display, etc.) are simple value types,
                // NOT deeply nested generics, so `as?` casts are safe here.
                if let prop = property {
                    applyStylePropertyViaMirror(prop, context: &context)
                }

                // Continue unwrapping with the inner content
                if let c = content {
                    current = c
                    continue
                } else {
                    return // Empty content - nothing to render
                }
            } else {
                // Not a Styled wrapper anymore - hand off to inner content renderer.
                // The inner content might still be CSS or _Attributes wrapper!
                renderInnerContent(current, context: &context)
                return
            }
        }
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
        // The property field in HTML.Styled is `let property: P?` (optional).
        // We need to unwrap the Optional to get the actual property value.
        let unwrapped: Any
        let propMirror = Mirror(reflecting: prop)
        if propMirror.displayStyle == .optional {
            // It's an Optional - extract the wrapped value if present
            if let firstChild = propMirror.children.first {
                unwrapped = firstChild.value
            } else {
                return // Optional is nil - no property to apply
            }
        } else {
            unwrapped = prop
        }

        // Now we can safely cast to the modifier protocols.
        // These property types are simple structs (FontWeight, Color, etc.),
        // not deeply nested generics, so the cast won't crash.
        if let modifier = unwrapped as? any PDF.HTML.StyleModifier {
            modifier.apply(to: &context.pdf, configuration: context.configuration)
        }

        // Some properties affect the HTML context rather than PDF style
        // (e.g., page-break-after, break-inside for pagination control)
        if let htmlModifier = unwrapped as? any PDF.HTML.HTMLContextStyleModifier {
            htmlModifier.apply(to: &context)
        }
    }

    /// Render content that has been extracted from a wrapper type.
    ///
    /// CRITICAL: Even after extracting content from one wrapper, it might still
    /// be wrapped in a DIFFERENT wrapper type. For example:
    ///
    /// ```
    /// CSS<Styled<_Attributes<Element>>>
    ///   ↓ renderCSSWrapperViaMirror extracts base →
    /// Styled<_Attributes<Element>>     // Still a wrapper!
    ///   ↓ renderInnerContent sees it's Styled, calls renderStyledViaMirror →
    /// _Attributes<Element>             // Still a wrapper!
    ///   ↓ renderInnerContent sees it's _Attributes, calls renderAttributesViaMirror →
    /// Element                          // Finally not a wrapper
    ///   ↓ can safely use as? cast now
    /// ```
    ///
    /// This is why we MUST check for wrapper types via Mirror at every entry point.
    private static func renderInnerContent(
        _ value: Any,
        context: inout PDF.HTML.Context
    ) {
        // ⚠️ CRITICAL: Check for wrapper types via Mirror FIRST, before any as? cast.
        // The content we extracted might be wrapped in a DIFFERENT wrapper type.
        // Doing `as?` on a still-wrapped deeply-nested type will crash!
        let mirror = Mirror(reflecting: value)

        if isStyledType(mirror) {
            renderStyledViaMirror(value, context: &context)
            return
        }

        if isCSSWrapperType(mirror) {
            renderCSSWrapperViaMirror(mirror, context: &context)
            return
        }

        if isAttributesType(mirror) {
            renderAttributesViaMirror(mirror, context: &context)
            return
        }

        if isConditionalType(mirror) {
            renderConditionalViaMirror(mirror, context: &context)
            return
        }

        if isOptionalType(mirror) {
            renderOptionalViaMirror(mirror, context: &context)
            return
        }

        // ────────────────────────────────────────────────────────────────────────
        // At this point, we've confirmed the value is NOT a wrapper type.
        // It's now safe to use `as?` casts because the type is not deeply nested.
        // ────────────────────────────────────────────────────────────────────────

        // String is a common leaf type - render directly
        if let str = value as? String {
            String._render(str, context: &context)
            return
        }

        // Check for PDF.HTML.View conformance - use static dispatch if possible
        if let pdfView = value as? any PDF.HTML.View {
            func render<V: PDF.HTML.View>(_ v: V) {
                V._render(v, context: &context)
            }
            render(pdfView)
            return
        }

        // Handle types with conditional conformances that Swift can't verify at runtime.
        // These use marker protocols that are always conformed to, allowing dynamic dispatch.

        if let tuple = value as? any _TupleContent {
            tuple._renderEachElementDynamically(context: &context)
            return
        }

        if let element = value as? any _HTMLElementContent {
            element._renderElementDynamically(context: &context)
            return
        }

        if let anyView = value as? any _AnyViewContent {
            anyView._renderAnyViewDynamically(context: &context)
            return
        }

        if value is any _HTMLRawContent {
            return // Raw HTML (scripts, etc.) has no PDF representation
        }

        if let optional = value as? any _OptionalContent {
            optional._renderOptionalDynamically(context: &context)
            return
        }

        if let conditional = value as? any _ConditionalContent {
            conditional._renderConditionalDynamically(context: &context)
            return
        }

        if let array = value as? any _ArrayContent {
            array._renderArrayDynamically(context: &context)
            return
        }

        // Last resort: if it's an HTML.View, render its body.
        // This handles custom view types that don't have explicit PDF conformance.
        //
        // ⚠️ WARNING: This calls `.body` on the view, which will CRASH for wrapper
        // types that have `var body: Never { fatalError(...) }`. That's why we
        // MUST check for wrapper types first!
        if let htmlView = value as? any HTML.View {
            func renderBody<V: HTML.View>(_ v: V) {
                renderHTMLView(v.body, context: &context)
            }
            renderBody(htmlView)
        }
    }

    /// Render `HTML.CSS` wrapper by extracting and rendering its base content.
    ///
    /// HTML.CSS is a thin wrapper used for CSS property chaining syntax:
    /// `element.css.display(.flex).flexDirection(.column)`
    ///
    /// Each CSS property call wraps in Styled, but the `.css` accessor wraps in CSS.
    /// For PDF rendering, CSS wrapper itself has no effect - we just pass through.
    private static func renderCSSWrapperViaMirror(
        _ mirror: Mirror,
        context: inout PDF.HTML.Context
    ) {
        // Extract the "base" field which contains the wrapped content
        for child in mirror.children {
            if child.label == "base" {
                // The base content might be ANOTHER wrapper type!
                // Check via Mirror before proceeding.
                let baseMirror = Mirror(reflecting: child.value)

                if isStyledType(baseMirror) {
                    renderStyledViaMirror(child.value, context: &context)
                } else if isCSSWrapperType(baseMirror) {
                    renderCSSWrapperViaMirror(baseMirror, context: &context)
                } else if isAttributesType(baseMirror) {
                    renderAttributesViaMirror(baseMirror, context: &context)
                } else if isConditionalType(baseMirror) {
                    renderConditionalViaMirror(baseMirror, context: &context)
                } else if isOptionalType(baseMirror) {
                    renderOptionalViaMirror(baseMirror, context: &context)
                } else {
                    // Not a wrapper - safe to process with potential as? casts
                    renderInnerContent(child.value, context: &context)
                }
                return
            }
        }
    }

    /// Render `HTML._Attributes` wrapper by extracting and rendering its content.
    ///
    /// HTML._Attributes wraps content with HTML attributes (id, class, href, etc.).
    /// These attributes are only meaningful for HTML output, not PDF, so we simply
    /// extract the inner content and render it, ignoring the attributes.
    private static func renderAttributesViaMirror(
        _ mirror: Mirror,
        context: inout PDF.HTML.Context
    ) {
        // Extract the "content" field (ignore "attributes" - not relevant for PDF)
        for child in mirror.children {
            if child.label == "content" {
                // The content might be ANOTHER wrapper type!
                // Check via Mirror before proceeding.
                let contentMirror = Mirror(reflecting: child.value)

                if isStyledType(contentMirror) {
                    renderStyledViaMirror(child.value, context: &context)
                } else if isCSSWrapperType(contentMirror) {
                    renderCSSWrapperViaMirror(contentMirror, context: &context)
                } else if isAttributesType(contentMirror) {
                    renderAttributesViaMirror(contentMirror, context: &context)
                } else if isConditionalType(contentMirror) {
                    renderConditionalViaMirror(contentMirror, context: &context)
                } else if isOptionalType(contentMirror) {
                    renderOptionalViaMirror(contentMirror, context: &context)
                } else {
                    // Not a wrapper - safe to process with potential as? casts
                    renderInnerContent(child.value, context: &context)
                }
                return
            }
        }
    }

    /// Render `_Conditional` by extracting the active case's associated value via Mirror.
    ///
    /// _Conditional is an enum with either `.first(First)` or `.second(Second)`.
    /// We extract the associated value and render it, avoiding unsafe `as?` casts
    /// that can crash with SIGBUS when the conditional's branches contain
    /// deeply nested generic types.
    ///
    /// Flow:
    /// ```
    /// _Conditional<TableRow<...>, Empty>
    ///   ↓ check displayStyle == .enum
    ///   ↓ extract child with label "first" or "second"
    /// TableRow<...>
    ///   ↓ pass to renderInnerContent (which checks for more wrappers)
    /// ```
    private static func renderConditionalViaMirror(
        _ mirror: Mirror,
        context: inout PDF.HTML.Context
    ) {
        // Enum Mirror has one child: the active case with its associated value
        for child in mirror.children {
            if child.label == "first" || child.label == "second" {
                // The associated value might itself be a wrapper type
                renderInnerContent(child.value, context: &context)
                return
            }
        }
        // No case found (shouldn't happen for valid _Conditional)
    }

    /// Render `Optional` by extracting the wrapped value via Mirror.
    ///
    /// Optional is an enum with `.none` or `.some(Wrapped)`.
    /// For `if` without `else` in result builders, buildOptional returns Optional<T>.
    /// We extract the wrapped value (if present) and render it.
    ///
    /// Flow:
    /// ```
    /// Optional<TableRow<...>>
    ///   ↓ check displayStyle == .optional
    ///   ↓ if .some, extract the wrapped value (first child)
    /// TableRow<...>
    ///   ↓ pass to renderInnerContent (which checks for more wrappers)
    /// ```
    private static func renderOptionalViaMirror(
        _ mirror: Mirror,
        context: inout PDF.HTML.Context
    ) {
        // Optional Mirror has either:
        // - No children for .none
        // - One child with label "some" for .some(value)
        for child in mirror.children {
            if child.label == "some" {
                // The wrapped value might itself be a wrapper type
                renderInnerContent(child.value, context: &context)
                return
            }
        }
        // .none case - nothing to render
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
        beforeSpacing: PDF.UserSpace.Height = 0,
        afterSpacing: PDF.UserSpace.Height = 0
    ) {
        // Flush pending inline runs
        if context.pdf.hasInlineRuns {
            context.pdf.flushInlineRuns()
        }

        // Add spacing before
        if beforeSpacing > 0 {
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
        if afterSpacing > 0 {
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
