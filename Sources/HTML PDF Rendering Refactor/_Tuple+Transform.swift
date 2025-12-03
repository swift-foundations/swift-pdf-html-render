// _Tuple+Transform.swift
// Tuple transforms each element in sequence

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Tuple: PDF.Transform where repeat each Content: HTML.View {
    public static func _transform(
        _ view: Self,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        func transformElement<T: HTML.View>(_ element: T) {
            PDF.transform(element, context: &context, configuration: configuration)
        }

        repeat transformElement(each view.content)
    }
}
