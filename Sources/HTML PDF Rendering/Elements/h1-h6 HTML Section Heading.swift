// h1-h6 HTML Section Heading.swift

import HTML_Rendering
import PDF_Rendering

extension H1 {
    /// Convert h1 element to PDF view
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createHeading(level: 1, content: content, configuration: configuration, style: style)
    }
}

extension H2 {
    /// Convert h2 element to PDF view
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createHeading(level: 2, content: content, configuration: configuration, style: style)
    }
}

extension H3 {
    /// Convert h3 element to PDF view
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createHeading(level: 3, content: content, configuration: configuration, style: style)
    }
}

extension H4 {
    /// Convert h4 element to PDF view
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createHeading(level: 4, content: content, configuration: configuration, style: style)
    }
}

extension H5 {
    /// Convert h5 element to PDF view
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createHeading(level: 5, content: content, configuration: configuration, style: style)
    }
}

extension H6 {
    /// Convert h6 element to PDF view
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createHeading(level: 6, content: content, configuration: configuration, style: style)
    }
}

/// Create a heading view with appropriate size and spacing
private func createHeading(
    level: Int,
    content: String,
    configuration: HTML.Configuration,
    style: HTML.ComputedStyle
) -> any PDF.View {
    let headingSize = configuration.headingSize(level: level)
    let headingStyle = style.merging(HTML.ComputedStyle(
        fontSize: headingSize,
        fontWeight: .bold
    ))

    let childView = HTML.ElementMapping.convertHTMLString(
        content,
        configuration: configuration,
        style: headingStyle
    )
    let spacing = headingSize * 0.5
    return PDF.VStack(spacing: 0, children: [
        PDF.Spacer(spacing),
        childView,
        PDF.Spacer(spacing * 0.5)
    ])
}
