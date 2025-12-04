// _Tuple+PDF.HTML.View.swift
// Tuple renders each element in sequence

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Tuple: PDF.HTML.View where repeat each Content: PDF.HTML.View {
    @inlinable
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        func render<T: PDF.HTML.View>(_ element: T) {
            T._render(element, into: &buffer, context: &context, configuration: configuration)
        }
        repeat render(each view.content)
    }
}
