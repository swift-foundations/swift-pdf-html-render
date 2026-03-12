// PDF.Document+HTML.swift
// Create PDF documents from HTML content

import HTML_Renderable
import ISO_32000
import PDF_Rendering
import PDF_Standard

extension PDF.Document {
    /// Create a PDF document from HTML content.
    ///
    /// Example:
    /// ```swift
    /// let doc = PDF.Document {
    ///     H1 { "Hello" }
    ///     Paragraph { "World" }
    /// }
    /// let bytes = [UInt8](doc)
    /// ```
    ///
    /// - Parameters:
    ///   - info: Document metadata (title, author, etc.)
    ///   - configuration: PDF rendering configuration
    ///   - generateOutline: If true, generates bookmarks from H1-H6 headings (default: false)
    ///   - html: The HTML content to render
    public init<H: HTML_Renderable.HTML.View>(
        info: ISO_32000.Document.Info? = nil,
        configuration: PDF.HTML.Configuration = .init(),
        generateOutline: Bool = false,
        @HTML_Renderable.HTML.Builder _ html: () -> H
    ) {
        // Build viewer from configuration, converting nested types
        let viewer = ISO_32000.Viewer(
            hideToolbar: configuration.viewer.hideToolbar,
            hideMenubar: configuration.viewer.hideMenubar,
            hideWindowUI: configuration.viewer.hideWindowUI,
            fitWindow: configuration.viewer.fitWindow,
            centerWindow: configuration.viewer.centerWindow,
            displayDocTitle: configuration.viewer.displayDocTitle,
            nonFullScreenPageMode: configuration.viewer.nonFullScreenPageMode,
            direction: configuration.viewer.direction,
            view: .init(
                area: configuration.viewer.view.area,
                clip: configuration.viewer.view.clip
            ),
            print: .init(
                area: configuration.viewer.print.area,
                clip: configuration.viewer.print.clip,
                scaling: configuration.viewer.print.scaling
            )
        )

        // Only include viewer if it differs from defaults
        let viewerOrNil: ISO_32000.Viewer? = configuration.viewer == .init()
            ? nil
            : viewer

        if generateOutline {
            // Use render() to get pages and collected headings
            let result = PDF.HTML.render(
                configuration: configuration,
                html: html
            )

            // Build outline from collected headings
            // Note: HeadingEntry uses 1-indexed pageNumber, Outline.build expects 0-indexed pageIndex
            let outline = ISO_32000.Outline.build(
                from: result.headings.map { heading in
                    (
                        level: heading.level,
                        title: heading.text,
                        pageIndex: heading.pageNumber - 1,
                        yPosition: heading.yPosition
                    )
                },
                openToLevel: configuration.outline.openToLevel,
                color: configuration.outline.color,
                flags: configuration.outline.flags
            )

            // Note: Preview.app has a known quirk where single top-level outline items
            // are not displayed. The PDF structure is correct; other viewers (Chrome,
            // Adobe Reader, etc.) will show the outline properly.

            // Create document with outline
            self.init(
                info: info,
                pages: result.pages,
                outline: outline.isEmpty ? nil : outline,
                viewer: viewerOrNil
            )
        } else {
            // Simple path without outline generation
            let pages = PDF.HTML.pages(
                configuration: configuration,
                html: html
            )

            self.init(
                info: info,
                pages: pages,
                viewer: viewerOrNil
            )
        }
    }
}
