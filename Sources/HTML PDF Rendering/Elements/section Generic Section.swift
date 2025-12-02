// section Generic Section.swift

import HTML_Rendering
import PDF_Rendering

extension Section {
    /// Convert section element to PDF view
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
