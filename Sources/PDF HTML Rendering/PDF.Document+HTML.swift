import HTML_Rendering_Core
import ISO_32000
import PDF_Rendering
import PDF_Standard

extension PDF.Document {

    public init<H: HTML_Rendering_Core.HTML.View>(
        info: ISO_32000.Document.Info? = nil,
        configuration: PDF.HTML.Configuration = .init(),
        generateOutline: Bool = false,
        @HTML_Rendering_Core.HTML.Builder _ html: () -> H
    ) {

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

        let viewerOrNil: ISO_32000.Viewer? =
            configuration.viewer == .init()
            ? nil
            : viewer

        if generateOutline {

            let result = PDF.HTML.render(
                configuration: configuration,
                html: html
            )

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

            self.init(
                info: info,
                pages: result.pages,
                outline: outline.isEmpty ? nil : outline,
                viewer: viewerOrNil
            )
        } else {

            let pages = PDF.HTML.pages(
                configuration: configuration,
                content: html
            )

            self.init(
                info: info,
                pages: pages,
                viewer: viewerOrNil
            )
        }
    }
}
