// _Conditional+HTMLToPDFConvertible.swift

import HTML_Renderable
import PDF_Rendering
import Renderable

extension _Conditional: HTMLToPDFConvertible
where First: HTML.View, Second: HTML.View {
    public func renderToPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle,
        context: inout PDF.Context
    ) -> PDF.Content {
        switch self {
        case .first(let first):
            return convertToPDF(
                first,
                configuration: configuration,
                style: style,
                context: &context
            )
        case .second(let second):
            return convertToPDF(
                second,
                configuration: configuration,
                style: style,
                context: &context
            )
        }
    }
}
