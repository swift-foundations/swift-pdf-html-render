// strong Strong Importance.swift

import HTML_Rendering
import PDF_Rendering

extension StrongImportance {
    /// Convert strong element to PDF view with bold styling
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        let boldStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
        return HTML.ElementMapping.convertHTMLString(
            content,
            configuration: configuration,
            style: boldStyle
        )
    }
}
