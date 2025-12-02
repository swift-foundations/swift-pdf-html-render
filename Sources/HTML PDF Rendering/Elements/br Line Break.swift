// br Line Break.swift

import HTML_Rendering
import PDF_Rendering

extension BR {
    /// Convert br element to PDF spacer
    public static func toPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        PDF.Spacer(style.fontSize ?? configuration.defaultFontSize)
    }
}
