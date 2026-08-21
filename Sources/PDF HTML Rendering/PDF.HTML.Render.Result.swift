import PDF_Rendering

extension PDF.HTML {

    public enum Render {}
}

extension PDF.HTML {

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
        pdfContext.style.lineHeight = Dimension_Primitives.Scale(
            configuration.resolveLineHeight(
                for: configuration.defaultFont,
                fontSize: configuration.defaultFontSize
            )
        )
        return Self.Context(pdf: pdfContext, configuration: configuration)
    }

    static func finalizeRendering(
        context: inout PDF.HTML.Context
    ) -> Render.Result {
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

extension PDF.HTML.Render {

    public struct Result: Sendable {

        public let pages: [PDF.Page]

        public let headings: [PDF.HTML.Context.Section.HeadingEntry]

        public let namedDestinations: [String: PDF.HTML.Context.Link.Destination]
    }
}
