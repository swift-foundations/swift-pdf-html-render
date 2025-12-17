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
    /// Dynamic dispatch helper for rendering any HTML.View.
    ///
    /// Uses Mirror-based detection for HTML.Styled to avoid Swift runtime crashes
    /// on deeply nested generic types like `HTML.Styled<HTML.Styled<...>>`.
    ///
    /// The Mirror approach identifies HTML.Styled by field structure rather than
    /// protocol conformance, which doesn't trigger the problematic type metadata
    /// instantiation that causes `EXC_BAD_ACCESS` crashes.
    public static func renderHTMLView(
        _ view: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        // CRITICAL: Use Mirror to detect wrapper types BEFORE any as? cast.
        // Doing `as?` on deeply nested generics crashes Swift's runtime.
        let mirror = Mirror(reflecting: view)

        // Check for HTML.Styled (has "content" and "property" fields)
        if isStyledType(mirror) {
            renderStyledViaMirror(view, context: &context)
            return
        }

        // Check for HTML.CSS wrapper (has only "base" field)
        // This can also create deep nesting when combined with Styled
        if isCSSWrapperType(mirror) {
            renderCSSWrapperViaMirror(mirror, context: &context)
            return
        }

        // Check for HTML._Attributes wrapper (has "content" and "attributes" fields)
        // This can also create deep nesting when chaining .attribute() calls
        if isAttributesType(mirror) {
            renderAttributesViaMirror(mirror, context: &context)
            return
        }

        // For non-wrapper types, as? casts are safe (they don't create deep generic nesting)
        func renderPDFView<V: PDF.HTML.View>(_ v: V) {
            V._render(v, context: &context)
        }

        // 1. Handle HTML.AnyView first (before static dispatch to avoid infinite recursion)
        if let anyView = view as? any _AnyViewContent {
            anyView._renderAnyViewDynamically(context: &context)
            return
        }

        // 2. Try static dispatch for PDF.HTML.View conforming types
        if let pdfView = view as? any PDF.HTML.View {
            renderPDFView(pdfView)
            return
        }

        // 3. Handle _Tuple - Swift can't verify variadic conditional conformances at runtime
        if let tuple = view as? any _TupleContent {
            tuple._renderEachElementDynamically(context: &context)
            return
        }

        // 4. Handle HTML.Element.Tag - Swift can't verify conditional conformance at runtime
        if let element = view as? any _HTMLElementContent {
            element._renderElementDynamically(context: &context)
            return
        }

        // 5. Handle HTML.Raw - ignore in PDF context
        if view is any _HTMLRawContent {
            return
        }

        // 6. Handle Optional - Swift can't verify conditional conformance at runtime
        if let optional = view as? any _OptionalContent {
            optional._renderOptionalDynamically(context: &context)
            return
        }

        // 7. Handle _Conditional - Swift can't verify conditional conformance at runtime
        if let conditional = view as? any _ConditionalContent {
            conditional._renderConditionalDynamically(context: &context)
            return
        }

        // 8. Handle _Array - Swift can't verify conditional conformance at runtime
        if let array = view as? any _ArrayContent {
            array._renderArrayDynamically(context: &context)
            return
        }

        // 9. Fallback: render the body recursively (for custom HTML.View types)
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

// MARK: - Mirror-Based Rendering (Avoids as? crashes on deeply nested generics)

extension PDF.HTML {
    /// Check if a value is an HTML.Styled type using Mirror (without as? cast).
    ///
    /// HTML.Styled is identified by having both "content" and "property" fields.
    /// This avoids the Swift runtime crash that occurs when doing `as?` on deeply
    /// nested generic types.
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

    /// Check if a value is an HTML.CSS wrapper type using Mirror.
    ///
    /// HTML.CSS is identified by having only a "base" field (without "renderFunction"
    /// which would indicate AnyView).
    private static func isCSSWrapperType(_ mirror: Mirror) -> Bool {
        var hasBase = false
        var hasRenderFunction = false
        for child in mirror.children {
            if child.label == "base" { hasBase = true }
            if child.label == "renderFunction" { hasRenderFunction = true }
        }
        // HTML.CSS has only "base", AnyView has both "base" and "renderFunction"
        return hasBase && !hasRenderFunction
    }

    /// Check if a value is an HTML._Attributes type using Mirror.
    ///
    /// HTML._Attributes is identified by having "content" and "attributes" fields.
    /// Note: HTML.Styled also has "content" but has "property" instead of "attributes".
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

    /// Render HTML.Styled content via Mirror traversal.
    ///
    /// This iteratively processes nested HTML.Styled wrappers without using `as?`,
    /// collecting all styles and then rendering the innermost non-Styled content.
    static func renderStyledViaMirror(
        _ value: Any,
        context: inout PDF.HTML.Context
    ) {
        // Save style state at the outermost level
        let savedStyle = context.pdf.style
        defer { context.pdf.style = savedStyle }

        // Iteratively unwrap nested HTML.Styled layers
        var current: Any = value
        while true {
            let mirror = Mirror(reflecting: current)

            // Check if current is HTML.Styled
            if isStyledType(mirror) {
                var content: Any?
                var property: Any?

                for child in mirror.children {
                    switch child.label {
                    case "content": content = child.value
                    case "property": property = child.value
                    default: break
                    }
                }

                // Apply style property (property types are simple, safe to cast)
                if let prop = property {
                    applyStylePropertyViaMirror(prop, context: &context)
                }

                // Continue with content
                if let c = content {
                    current = c
                    continue
                } else {
                    return // No content
                }
            } else {
                // Not HTML.Styled - render the inner content using safe dispatch
                renderInnerContent(current, context: &context)
                return
            }
        }
    }

    /// Apply a CSS property to the context.
    /// Property types are simple value types (not deeply nested), so casting is safe.
    private static func applyStylePropertyViaMirror(
        _ prop: Any,
        context: inout PDF.HTML.Context
    ) {
        // Unwrap Optional wrapper if present
        let unwrapped: Any
        let propMirror = Mirror(reflecting: prop)
        if propMirror.displayStyle == .optional {
            if let firstChild = propMirror.children.first {
                unwrapped = firstChild.value
            } else {
                return // nil property
            }
        } else {
            unwrapped = prop
        }

        // Cast to PDF style modifier (safe - property types are simple)
        if let modifier = unwrapped as? any PDF.HTML.StyleModifier {
            modifier.apply(to: &context.pdf, configuration: context.configuration)
        }

        // Check for HTML context modifier (for page-break-after, break-inside, etc.)
        if let htmlModifier = unwrapped as? any PDF.HTML.HTMLContextStyleModifier {
            htmlModifier.apply(to: &context)
        }
    }

    /// Render inner (non-Styled) content using safe dispatch methods.
    ///
    /// Once we've unwrapped all HTML.Styled layers via Mirror, the inner content
    /// is no longer deeply nested in generics, so we can safely use `as?` checks.
    /// However, we still need to check for wrapper types via Mirror first since
    /// they may still be nested with each other.
    private static func renderInnerContent(
        _ value: Any,
        context: inout PDF.HTML.Context
    ) {
        // CRITICAL: Check for wrapper types via Mirror FIRST before any as? casts.
        // These types can still be nested with each other (CSS wrapping Attributes, etc.)
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

        // Simple types - safe to cast
        if let str = value as? String {
            String._render(str, context: &context)
            return
        }

        // Check for PDF.HTML.View conformance (now safe - not deeply nested)
        if let pdfView = value as? any PDF.HTML.View {
            func render<V: PDF.HTML.View>(_ v: V) {
                V._render(v, context: &context)
            }
            render(pdfView)
            return
        }

        // Handle marker protocols for types with conditional conformances
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
            return // Ignore raw HTML in PDF
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

        // Fallback: try to render body for HTML.View types
        if let htmlView = value as? any HTML.View {
            func renderBody<V: HTML.View>(_ v: V) {
                renderHTMLView(v.body, context: &context)
            }
            renderBody(htmlView)
        }
    }

    /// Render HTML.CSS wrapper content via Mirror traversal.
    ///
    /// HTML.CSS wraps content and may itself be nested inside HTML.Styled or vice versa.
    /// We extract the "base" field and recursively render it.
    private static func renderCSSWrapperViaMirror(
        _ mirror: Mirror,
        context: inout PDF.HTML.Context
    ) {
        // Extract the "base" field
        for child in mirror.children {
            if child.label == "base" {
                // The base content might be another wrapper type (Styled, CSS, or Attributes)
                // so we need to check it again via Mirror
                let baseMirror = Mirror(reflecting: child.value)

                if isStyledType(baseMirror) {
                    renderStyledViaMirror(child.value, context: &context)
                } else if isCSSWrapperType(baseMirror) {
                    renderCSSWrapperViaMirror(baseMirror, context: &context)
                } else if isAttributesType(baseMirror) {
                    renderAttributesViaMirror(baseMirror, context: &context)
                } else {
                    // Inner content is not a wrapper - render using safe dispatch
                    renderInnerContent(child.value, context: &context)
                }
                return
            }
        }
    }

    /// Render HTML._Attributes wrapper content via Mirror traversal.
    ///
    /// HTML._Attributes wraps content with HTML attributes. The attributes are
    /// not relevant for PDF rendering, so we just extract and render the content.
    private static func renderAttributesViaMirror(
        _ mirror: Mirror,
        context: inout PDF.HTML.Context
    ) {
        // Extract the "content" field (ignore "attributes" - not relevant for PDF)
        for child in mirror.children {
            if child.label == "content" {
                // The content might be another wrapper type (Styled, CSS, or more Attributes)
                // so we need to check it again via Mirror
                let contentMirror = Mirror(reflecting: child.value)

                if isStyledType(contentMirror) {
                    renderStyledViaMirror(child.value, context: &context)
                } else if isCSSWrapperType(contentMirror) {
                    renderCSSWrapperViaMirror(contentMirror, context: &context)
                } else if isAttributesType(contentMirror) {
                    renderAttributesViaMirror(contentMirror, context: &context)
                } else {
                    // Inner content is not a wrapper - render using safe dispatch
                    renderInnerContent(child.value, context: &context)
                }
                return
            }
        }
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
