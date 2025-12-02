// hr Horizontal Rule.swift

import HTML_Rendering
import PDF_Rendering

extension ThematicBreak {
    /// Convert hr element to PDF divider
    public static func toPDF(
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        PDF.Divider()
    }
}
