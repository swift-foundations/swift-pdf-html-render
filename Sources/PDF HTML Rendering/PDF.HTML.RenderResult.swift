// PDF.HTML.RenderResult.swift
// Shared rendering infrastructure and result type

import PDF_Rendering

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
