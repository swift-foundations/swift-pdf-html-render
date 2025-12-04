// HTML.AnyView+PDF.HTML.View.swift
// PDF rendering for type-erased HTML.AnyView

import HTML_Renderable
import PDF_Rendering

extension HTML.AnyView: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Use dynamic dispatch to render the wrapped base view
        PDF.HTML.render(view.base, into: &buffer, context: &context, configuration: configuration)
    }
}
