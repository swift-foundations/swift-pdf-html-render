// ListItem+PDF.HTML.View.swift
// <li> element transformation - list item

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension ListItem: PDF.HTML.ListItemRenderer {
    static func renderMarker(
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) -> PDF.UserSpace.Width {
        // Marker rendering is handled in HTML.Element+PDF.HTML.View
        // This method returns the marker width for positioning
        let marker = context.nextListMarker()
        return PDF.UserSpace.Width(context.font.stringWidth(marker + " ", atSize: context.fontSize))
    }
}
