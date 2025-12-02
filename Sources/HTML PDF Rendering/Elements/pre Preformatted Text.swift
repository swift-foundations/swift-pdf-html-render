// pre Preformatted Text.swift

import HTML_Rendering
import PDF_Rendering

extension PreformattedText {
    /// Convert pre element to PDF view with monospace styling
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        let monoStyle = style.merging(HTML.ComputedStyle(
            fontSize: (style.fontSize ?? configuration.defaultFontSize) * 0.9
        ))
        return HTML.ElementMapping.convertHTMLString(
            content,
            configuration: configuration,
            style: monoStyle
        )
    }
}
