// PDF.HTML+EntryPoints.swift
// Public entry points for HTML to PDF rendering

import HTML_Rendering_Core
import PDF_Rendering
import Render_Primitives
import Ownership_Mutable_Primitives

// MARK: - Entry Points

extension PDF.HTML {
//    /// Render HTML content to PDF pages.
//    public static func pages<H: Render_Primitives.Render.View>(
//        configuration: PDF.HTML.Configuration = .init(),
//        @HTML.Builder html: () -> H
//    ) -> [PDF.Page] {
//        let state = Ownership.Mutable(prepareContext(configuration: configuration))
//        var renderCtx = Render_Primitives.Render.Context.pdfHTML(state: state)
//        renderCtx.render(html())
//        return finalizeRendering(context: &state.value).pages
//    }

    /// Render HTML content to PDF pages with collected metadata.
    public static func render<H: Render_Primitives.Render.View>(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder html: () -> H
    ) -> Render.Result {
        let state = Ownership.Mutable(prepareContext(configuration: configuration))
        var renderCtx = Render_Primitives.Render.Context.pdfHTML(state: state)
        renderCtx.render(html())
        return finalizeRendering(context: &state.value)
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
    public static func pages<
        Content: Render_Primitives.Render.View,
        Header: Render_Primitives.Render.View,
        Footer: Render_Primitives.Render.View
    >(
        configuration: PDF.HTML.Configuration = .init(),
        @HTML.Builder content: () -> Content,
        @HTML.Builder header: @escaping (Page.Info) -> Header = { _ in Render_Primitives.Render.Empty() },
        @HTML.Builder footer: @escaping (Page.Info) -> Footer = { _ in Render_Primitives.Render.Empty() }
    ) -> [PDF.Page] {
        // Adjust margins to account for header/footer space
        let adjustedMargins = PDF.UserSpace.Insets(
            top: configuration.margins.top + configuration.header.height,
            leading: configuration.margins.leading,
            bottom: configuration.margins.bottom + configuration.footer.height,
            trailing: configuration.margins.trailing
        )

        // PASS 1: Render content to get page count and section info
        var pass1Config = configuration
        pass1Config.margins = adjustedMargins

        let pass1State = Ownership.Mutable(prepareContext(configuration: pass1Config))
        let contentView = content()
        var pass1RenderCtx = Render_Primitives.Render.Context.pdfHTML(state: pass1State)
        pass1RenderCtx.render(contentView)

        pass1State.value.pdf.flush.inline()

        let totalPages = pass1State.value.pdf.pages.count
        let pageSectionTitles = pass1State.value.section.pageTitles

        // PASS 2: Render again with headers and footers
        // For each page, we render: header area, content area, footer area
        var finalPages: [PDF.Page] = []

        for pageNumber in 1...totalPages {
            let pageInfo = Page.Info(
                pageNumber: pageNumber,
                totalPages: totalPages,
                sectionTitle: pageSectionTitles[pageNumber],
                documentTitle: configuration.documentTitle,
                date: configuration.documentDate
            )

            // Create a single-page context for header
            var headerContext = PDF.Context(
                mediaBox: configuration.mediaBox,
                margins: PDF.UserSpace.Insets(
                    top: configuration.margins.top,
                    leading: configuration.margins.leading,
                    bottom: configuration.paperSize.height - configuration.margins.top - configuration.header.height,
                    trailing: configuration.margins.trailing
                )
            )
            headerContext.style = pass1State.value.pdf.style

            let headerState = Ownership.Mutable(PDF.HTML.Context(pdf: headerContext, configuration: configuration))
            var headerRenderCtx = Render_Primitives.Render.Context.pdfHTML(state: headerState)
            headerRenderCtx.render(header(pageInfo))
            headerState.value.pdf.flush.inline()

            // Create a single-page context for footer
            var footerContext = PDF.Context(
                mediaBox: configuration.mediaBox,
                margins: PDF.UserSpace.Insets(
                    top: configuration.paperSize.height - configuration.margins.bottom - configuration.footer.height,
                    leading: configuration.margins.leading,
                    bottom: configuration.margins.bottom,
                    trailing: configuration.margins.trailing
                )
            )
            footerContext.style = pass1State.value.pdf.style

            let footerState = Ownership.Mutable(PDF.HTML.Context(pdf: footerContext, configuration: configuration))
            var footerRenderCtx = Render_Primitives.Render.Context.pdfHTML(state: footerState)
            footerRenderCtx.render(footer(pageInfo))
            footerState.value.pdf.flush.inline()

            // Combine: get content page, header content, footer content
            let contentPage = pass1State.value.pdf.pages[pageNumber - 1]

            // Merge content streams: header + content + footer
            var mergedContents: [PDF.ContentStream] = []
            if let headerPage = headerState.value.pdf.pages.first {
                mergedContents.append(contentsOf: headerPage.contents)
            }
            mergedContents.append(contentsOf: contentPage.contents)
            if let footerPage = footerState.value.pdf.pages.first {
                mergedContents.append(contentsOf: footerPage.contents)
            }

            // Merge resources
            var mergedResources = contentPage.resources
            if let headerPage = headerState.value.pdf.pages.first {
                for (name, font) in headerPage.resources.fonts {
                    mergedResources.fonts[name] = font
                }
            }
            if let footerPage = footerState.value.pdf.pages.first {
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
