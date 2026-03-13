// PDF.HTML.Render.Result.swift
// Shared rendering infrastructure and result type

import PDF_Rendering

// MARK: - Render Namespace

extension PDF.HTML {
    /// Namespace for rendering result types.
    public enum Render {}
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
        pdfContext.style.lineHeight = Dimension_Primitives.Scale(configuration.resolveLineHeight(
            for: configuration.defaultFont,
            fontSize: configuration.defaultFontSize
        ))
        return PDF.HTML.Context(pdf: pdfContext, configuration: configuration)
    }

    /// Finalize rendering: flush deferred content, resolve internal links, return result.
    static func finalizeRendering(
        context: inout PDF.HTML.Context
    ) -> Render.Result {
        if let deferred = context.deferredKeepWithNextRender {
            context.deferredKeepWithNextRender = nil
            deferred.render(&context)
        }
        context.pdf.flush.inline()

        let resolvedPages = PDF.Context.resolveInternalLinks(
            pages: context.pdf.pages,
            pendingLinks: context.pdf.link.pending,
            namedDestinations: context.link.destinations.mapValues { dest in
                (pageNumber: dest.pageNumber, yPosition: dest.yPosition)
            }
        )
        return Render.Result(
            pages: resolvedPages,
            headings: context.section.headings,
            namedDestinations: context.link.destinations
        )
    }
}

// MARK: - Render Result

extension PDF.HTML.Render {
    /// Result of rendering HTML to PDF, including collected metadata for outlines.
    public struct Result: Sendable {
        /// The rendered PDF pages
        public let pages: [PDF.Page]
        /// Collected headings for outline/bookmark generation
        public let headings: [PDF.HTML.Context.Section.HeadingEntry]
        /// Named destinations for internal links
        public let namedDestinations: [String: PDF.HTML.Context.Link.Destination]
    }
}
