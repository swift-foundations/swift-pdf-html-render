// HTML.AnyView+PDF.HTML.View.swift
// PDF rendering for type-erased HTML.AnyView

import HTML_Renderable
import PDF_Rendering

// Note: HTML.AnyView does NOT conform to PDF.HTML.View to avoid infinite recursion.
// Instead, it's handled specially in renderHTMLView via _AnyViewContent protocol.

/// Marker protocol for HTML.AnyView dynamic dispatch.
package protocol _AnyViewContent {
    /// Render the wrapped view using dynamic dispatch.
    func _renderAnyViewDynamically(context: inout PDF.HTML.Context)
}

extension HTML.AnyView: _AnyViewContent {
    public func _renderAnyViewDynamically(context: inout PDF.HTML.Context) {
        // Use dynamic dispatch to handle the wrapped type
        func renderBase<V: HTML.View>(_ v: V) {
            PDF.HTML.renderHTMLView(v, context: &context)
        }
        renderBase(base)
    }
}
