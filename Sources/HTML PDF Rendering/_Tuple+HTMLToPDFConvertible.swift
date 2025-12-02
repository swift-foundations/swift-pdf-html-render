// _Tuple+HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Tuple: HTMLToPDFConvertible where repeat each Content: HTML.View {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        var operations: [PDF.Operation] = []

        func convert<T: HTML.View>(_ element: T) {
            let result = convertToPDF(
                element,
                configuration: configuration,
                style: style,
                context: &context
            )
            operations.append(contentsOf: result.operations)
        }

        repeat convert(each content)

        return PDF.Content(operations: operations)
    }
}
