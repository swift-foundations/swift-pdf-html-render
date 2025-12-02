// ul Unordered List.swift

import HTML_Rendering
import PDF_Rendering

extension UnorderedList {
    /// Convert ul element to PDF view with bullet points
    public static func toPDF(
        content: String,
        configuration: HTML.Configuration,
        style: HTML.ComputedStyle
    ) -> any PDF.View {
        createList(
            content: content,
            ordered: false,
            configuration: configuration,
            style: style
        )
    }
}

/// Create a list view (shared by ul and ol)
func createList(
    content: String,
    ordered: Bool,
    configuration: HTML.Configuration,
    style: HTML.ComputedStyle
) -> any PDF.View {
    var items: [any PDF.View] = []
    var itemIndex = 0

    var remaining = content[...]
    while let liStart = remaining.range(of: "<li") {
        if let tagEnd = remaining[liStart.upperBound...].firstIndex(of: ">") {
            let afterTag = remaining.index(after: tagEnd)

            if let closeStart = remaining[afterTag...].range(of: "</li>") {
                let itemContent = String(remaining[afterTag..<closeStart.lowerBound])
                itemIndex += 1

                let bullet = ordered ? "\(itemIndex). " : "• "
                let trimmedContent = String(itemContent.trimming(where: \.isWhitespace))
                let itemView = PDF.Text(
                    bullet + trimmedContent,
                    font: PDF.Font(style, base: configuration.defaultFont),
                    fontSize: style.fontSize ?? configuration.defaultFontSize,
                    color: style.color ?? configuration.defaultColor
                )
                items.append(itemView)

                remaining = remaining[closeStart.upperBound...]
            } else {
                break
            }
        } else {
            break
        }
    }

    let spacing = (style.fontSize ?? configuration.defaultFontSize) * 0.3
    return PDF.VStack(spacing: spacing, children: items)
}
