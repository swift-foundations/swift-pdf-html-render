// CSS+PDF.HTML.View.swift
// PDF rendering support for CSS<T> wrapper from swift-css

import CSS
import HTML_Renderable
import PDF_Rendering

/// PDF rendering for CSS<Base> wrapper.
///
/// The CSS wrapper is a passthrough - it simply renders its base content.
/// This enables `.css.color(.red)` style chains to render correctly to PDF.
extension CSS: PDF.HTML.View where Base: PDF.HTML.View {
    @inlinable
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // CSS wrapper is passthrough - render the base
        Base._render(view.base, into: &buffer, context: &context)
    }
}
