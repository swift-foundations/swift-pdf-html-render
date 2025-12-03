// _Conditional+HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Conditional: HTMLToPDFConvertible
where First: HTML.View, Second: HTML.View {
    // Note: Content = Never is already defined in _Conditional's HTML.View conformance

    public static func _renderToPDF(
        _ view: Self,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        switch view {
        case .first(let first):
            return PDF.Content(
                first,
                configuration: configuration,
                style: style,
                context: &context
            )
        case .second(let second):
            return PDF.Content(
                second,
                configuration: configuration,
                style: style,
                context: &context
            )
        }
    }
}
