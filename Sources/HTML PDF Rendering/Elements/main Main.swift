// main Main.swift

import HTML_Rendering
import PDF_Rendering

extension Main {
    /// Convert main element to PDF view
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
