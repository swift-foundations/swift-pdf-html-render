// HTML.AnyView+PDF.HTML.View.swift
// PDF rendering for type-erased HTML.AnyView

import HTML_Renderable
import PDF_Rendering

extension HTML.AnyView: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // We need to check if the base conforms to PDF.HTML.View
        // Since HTML.AnyView wraps `any HTML.View`, we use dynamic dispatch
        if let pdfView = view.base as? any PDF.HTML.View {
            func callRender<V: PDF.HTML.View>(_ v: V) {
                V._render(v, context: &context)
            }
            callRender(pdfView)
        }
        // If the wrapped type doesn't conform to PDF.HTML.View, nothing renders
    }
}
