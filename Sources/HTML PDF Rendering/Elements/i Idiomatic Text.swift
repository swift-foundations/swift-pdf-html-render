// i Idiomatic Text.swift

import HTML_Rendering
import PDF_Rendering

extension IdiomaticText {
    /// Convert i element to PDF view with italic styling
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
        return HTML.ElementMapping.convertHTMLString(
            content,
            configuration: configuration,
            style: italicStyle
        )
    }
}
