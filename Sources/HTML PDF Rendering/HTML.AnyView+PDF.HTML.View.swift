// HTML.AnyView+PDF.HTML.View.swift
// PDF rendering for type-erased HTML.AnyView

import HTML_Renderable
import PDF_Rendering

extension HTML.AnyView: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Use dynamic dispatch to render the wrapped base view
        func render<V: HTML.View>(_ html: V) where V: PDF.HTML.View {
            V._render(html, into: &buffer, context: &context)
        }

        // We need to check if the base conforms to PDF.HTML.View
        // Since HTML.AnyView wraps `any HTML.View`, we use dynamic dispatch
        if let pdfView = view.base as? any PDF.HTML.View {
            func callRender<V: PDF.HTML.View>(_ v: V) {
                V._render(v, into: &buffer, context: &context)
            }
            callRender(pdfView)
        }
        // If the wrapped type doesn't conform to PDF.HTML.View, nothing renders
    }
}
