// _Array+HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Array: HTMLToPDFConvertible where Element: HTML.View {
    // Note: Content = Never is already defined in _Array's HTML.View conformance

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        var operations: [PDF.Content.Operation] = []
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        let spacing = fontSize * 0.3

        for (index, element) in view.elements.enumerated() {
            let result = PDF.Content(
                element,
                configuration: configuration,
                style: style,
                context: &context
            )
            operations.append(contentsOf: result.operations)

            // Add spacing between elements (not after the last one)
            if index < view.elements.count - 1 {
                context.advanceY(spacing)
            }
        }

        return PDF.Content(operations: operations)
    }
}
