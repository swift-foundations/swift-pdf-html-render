// span Content Span.swift

import HTML_Rendering
import PDF_Rendering

extension ContentSpan {
    /// Convert span element to PDF view (pass-through)
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        HTML.ElementMapping.convertHTMLString(
            content,
            configuration: configuration,
            style: style
        )
    }
}
