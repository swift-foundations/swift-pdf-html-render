// _Array+HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Array: HTMLToPDFConvertible where Element: HTML.View {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        var operations: [PDF.Operation] = []
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        let spacing = fontSize * 0.3

        for (index, element) in elements.enumerated() {
            let result = convertToPDF(
                element,
                configuration: configuration,
                style: style,
                context: &context
            )
            operations.append(contentsOf: result.operations)

            // Add spacing between elements (not after the last one)
            if index < elements.count - 1 {
                context.advanceY(spacing)
            }
        }

        return PDF.Content(operations: operations)
    }
}
