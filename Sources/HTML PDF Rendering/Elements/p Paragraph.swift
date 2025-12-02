// p Paragraph.swift

import HTML_Rendering
import PDF_Rendering

extension Paragraph {
    /// Convert paragraph element to PDF view with spacing
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        let childView = HTML.ElementMapping.convertHTMLString(
            content,
            configuration: configuration,
            style: style
        )
        let spacing = (style.fontSize ?? configuration.defaultFontSize) * 0.5
        return PDF.VStack(spacing: 0, children: [
            childView,
            PDF.Spacer(spacing)
        ])
    }
}
