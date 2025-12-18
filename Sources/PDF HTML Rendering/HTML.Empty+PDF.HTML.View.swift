// HTML.Empty+PDF.HTML.View.swift
// HTML.Empty renders nothing

import HTML_Renderable
import PDF_Rendering

extension HTML.Empty: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Empty renders nothing
    }
}
