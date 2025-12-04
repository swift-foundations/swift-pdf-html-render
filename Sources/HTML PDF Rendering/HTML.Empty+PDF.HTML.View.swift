// HTML.Empty+PDF.HTML.View.swift
// HTML.Empty renders nothing

import HTML_Renderable
import PDF_Rendering

extension HTML.Empty: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Empty renders nothing
    }
}
