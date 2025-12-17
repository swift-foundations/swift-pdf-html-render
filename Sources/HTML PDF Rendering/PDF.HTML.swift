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
    /// Checks if the view conforms to PDF.HTML.View and dispatches accordingly.
    /// Falls back to rendering the body recursively if no explicit conformance.
    ///
    /// Note: Swift's runtime type checking doesn't work with conditional conformances
    /// on variadic generics (`_Tuple`), so we handle _Tuple specially by iterating
    /// its content.
    public static func renderHTMLView(
        _ view: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        // Inner helper to open existentials
        func renderPDFView<V: PDF.HTML.View>(_ v: V) {
            V._render(v, context: &context)
        }

        // 1. Try static dispatch if type conforms to PDF.HTML.View
        if let pdfView = view as? any PDF.HTML.View {
            renderPDFView(pdfView)
            return
        }

        // 2. Handle _Tuple specially - Swift can't verify variadic conditional conformances at runtime
        if let tuple = view as? any _TupleContent {
            tuple._renderEachElementDynamically(context: &context)
            return
        }

        // 3. Handle HTML.Element.Tag - Swift can't verify conditional conformance at runtime
        if let element = view as? any _HTMLElementContent {
            element._renderElementDynamically(context: &context)
            return
        }

        // 4. Handle HTML.Raw - ignore in PDF context (no meaningful representation)
        if view is any _HTMLRawContent {
            return
        }

        // 5. Handle Optional - Swift can't verify conditional conformance at runtime
        if let optional = view as? any _OptionalContent {
            optional._renderOptionalDynamically(context: &context)
            return
        }

        // 6. Handle HTML.Styled - Swift can't verify conditional conformance at runtime
        if let styled = view as? any _HTMLStyledContent {
            styled._renderStyledDynamically(context: &context)
            return
        }

        // 7. Fallback: render the body recursively (for custom HTML.View types)
        func renderBody<V: HTML.View>(_ v: V) {
            renderHTMLView(v.body, context: &context)
        }
        renderBody(view)
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
