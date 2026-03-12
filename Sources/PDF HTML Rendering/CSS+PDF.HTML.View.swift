// CSS+PDF.HTML.View.swift
// PDF rendering support for CSS<T> wrapper from swift-css

import CSS
public import CSS_HTML_Rendering
import HTML_Renderable
import PDF_Rendering

/// PDF rendering for HTML.CSS<Base> wrapper.
///
/// The CSS wrapper is a passthrough - it simply renders its base content.
/// This enables `.css.color(.red)` style chains to render correctly to PDF.
extension HTML.CSS: PDF.HTML.View where Base: PDF.HTML.View {
    @inlinable
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // CSS wrapper is passthrough - render the base
        Base._render(view.base, context: &context)
    }
}
