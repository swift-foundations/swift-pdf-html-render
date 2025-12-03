// _Tuple+HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Tuple: HTMLToPDFConvertible where repeat each Content: HTML.View {
    // Note: Content = Never is already defined in _Tuple's HTML.View conformance

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        var operations: [PDF.Content.Operation] = []

        func convert<T: HTML.View>(_ element: T) {
            let result = PDF.Content(
                element,
                configuration: configuration,
                style: style,
                context: &context
            )
            operations.append(contentsOf: result.operations)
        }

        repeat convert(each view.content)

        return PDF.Content(operations: operations)
    }
}
