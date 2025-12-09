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
        return PDF.UserSpace.Width(context.style.font.stringWidth(marker + " ", atSize: context.style.fontSize))
    }
}
