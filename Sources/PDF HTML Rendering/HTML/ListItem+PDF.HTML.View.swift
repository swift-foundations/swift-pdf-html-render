// ListItem+PDF.HTML.View.swift
// <li> element transformation - list item

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

// Note: ListItem is not generic, so we can't add a conditional conformance here.
// The PDF rendering for list items is handled in HTML.Element+PDF.HTML.View.swift
// which detects tag name "li" and uses the pending marker approach.
//
// The pending marker is stored in PDF.Context.pendingListMarker and is emitted
// when the first line of text is rendered, ensuring proper alignment even when
// the list item contains block elements with margins (like <p>).

extension ListItem: PDF.HTML.ListItemRenderer {
    public static func renderMarker(
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) -> PDF.UserSpace.Width {
        let marker = context.nextListMarker()
        let markerWidth: PDF.UserSpace.Width
        switch marker {
        case .text(let bytes, let font):
            markerWidth = font.winAnsi.width(of: bytes, atSize: context.style.fontSize)
        case .strokedCircle(let circle, _):
            markerWidth = circle.diameter.width
        case .filledCircle(let circle):
            markerWidth = circle.diameter.width
        case .filledSquare(let rect):
            markerWidth = rect.width
        }
        let spaceWidth = context.style.font.winAnsi.width(of: [.ascii.space], atSize: context.style.fontSize)
        return markerWidth + spaceWidth
    }
}
