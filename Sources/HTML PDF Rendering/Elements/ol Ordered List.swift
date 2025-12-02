// ol Ordered List.swift

import HTML_Rendering
import PDF_Rendering

extension OrderedList {
    /// Convert ol element to PDF view with numbered items
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createList(
            content: content,
            ordered: true,
            configuration: configuration,
            style: style
        )
    }
}
