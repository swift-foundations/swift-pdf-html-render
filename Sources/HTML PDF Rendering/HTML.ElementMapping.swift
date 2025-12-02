// HTML.ElementMapping.swift

public import PDF_Rendering
public import HTML_Rendering
import Standards

extension HTML {
    /// Maps HTML elements to PDF view primitives.
    ///
    /// This type provides the conversion logic from HTML.View trees
    /// to PDF.View primitives for rendering.
    public enum ElementMapping {

        /// Convert an HTML.View to a PDF.View
        public static func convert<T: HTML.View>(
            _ html: T,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle = .empty
        ) -> any PDF.View {
            // Get raw HTML bytes to analyze the structure
            var htmlContext = HTML.Context()
            var buffer: [UInt8] = []
            T._render(html, into: &buffer, context: &htmlContext)
            let htmlString = String(decoding: buffer, as: UTF8.self)

            // Parse and convert the HTML string to PDF views
            return convertHTMLString(
                htmlString,
                configuration: configuration,
                style: style
            )
        }

        /// Convert an HTML string to PDF views
        public static func convertHTMLString(
            _ html: String,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> any PDF.View {
            var children: [any PDF.View] = []
            var currentText = ""
            var index = html.startIndex

            while index < html.endIndex {
                let char = html[index]

                if char == "<" {
                    // Flush accumulated text
                    if !currentText.isEmpty {
                        let trimmed = String(currentText.trimming(where: \.isWhitespace))
                        if !trimmed.isEmpty {
                            children.append(createTextView(
                                trimmed,
                                configuration: configuration,
                                style: style
                            ))
                        }
                        currentText = ""
                    }

                    // Find the end of the tag
                    if let closeIndex = html[index...].firstIndex(of: ">") {
                        let tagContent = String(html[html.index(after: index)..<closeIndex])

                        // Check if it's a closing tag
                        if tagContent.hasPrefix("/") {
                            // Skip closing tags
                            index = html.index(after: closeIndex)
                            continue
                        }

                        // Parse the tag name
                        let tagName = parseTagName(tagContent)

                        // Handle void elements
                        if isVoidElement(tagName) {
                            if let view = handleVoidElement(
                                tagName,
                                attributes: parseAttributes(tagContent),
                                configuration: configuration,
                                style: style
                            ) {
                                children.append(view)
                            }
                            index = html.index(after: closeIndex)
                            continue
                        }

                        // Find matching closing tag and extract content
                        let nextIndex = html.index(after: closeIndex)
                        if let (content, endIndex) = extractElementContent(
                            html: html,
                            from: nextIndex,
                            tagName: tagName
                        ) {
                            let attributes = parseAttributes(tagContent)
                            let childStyle = style.merging(styleFromAttributes(attributes))

                            if let view = convertElement(
                                tagName: tagName,
                                content: content,
                                attributes: attributes,
                                configuration: configuration,
                                style: childStyle
                            ) {
                                children.append(view)
                            }
                            index = endIndex
                            continue
                        }

                        index = html.index(after: closeIndex)
                    } else {
                        currentText.append(char)
                        index = html.index(after: index)
                    }
                } else {
                    currentText.append(char)
                    index = html.index(after: index)
                }
            }

            // Flush remaining text
            if !currentText.isEmpty {
                let trimmed = String(currentText.trimming(where: \.isWhitespace))
                if !trimmed.isEmpty {
                    children.append(createTextView(
                        trimmed,
                        configuration: configuration,
                        style: style
                    ))
                }
            }

            // Return single child or wrap in VStack
            if children.isEmpty {
                return PDF.Content()
            } else if children.count == 1 {
                return children[0]
            } else {
                return PDF.VStack(spacing: configuration.lineHeight * configuration.defaultFontSize / 2, children: children)
            }
        }

        // MARK: - Parsing Helpers

        /// Parse tag name from tag content
        private static func parseTagName(_ tagContent: String) -> String {
            let content = String(tagContent.trimming(where: \.isWhitespace))
            if let spaceIndex = content.firstIndex(of: " ") {
                return String(content[..<spaceIndex]).lowercased()
            }
            return content.lowercased()
        }

        /// Parse attributes from tag content
        static func parseAttributes(_ tagContent: String) -> [String: String] {
            var attributes: [String: String] = [:]

            guard let spaceIndex = tagContent.firstIndex(of: " ") else {
                return attributes
            }

            var remaining = tagContent[tagContent.index(after: spaceIndex)...]

            while !remaining.isEmpty {
                remaining = remaining.drop(while: \.isWhitespace)
                guard !remaining.isEmpty else { break }

                var nameEnd = remaining.startIndex
                while nameEnd < remaining.endIndex && remaining[nameEnd] != "=" && !remaining[nameEnd].isWhitespace {
                    nameEnd = remaining.index(after: nameEnd)
                }

                let name = String(remaining[remaining.startIndex..<nameEnd])
                guard !name.isEmpty else { break }

                remaining = remaining[nameEnd...]
                remaining = remaining.drop(while: \.isWhitespace)

                if remaining.first == "=" {
                    remaining = remaining.dropFirst()
                    remaining = remaining.drop(while: \.isWhitespace)

                    if remaining.first == "\"" || remaining.first == "'" {
                        let quote = remaining.first!
                        remaining = remaining.dropFirst()
                        if let endQuote = remaining.firstIndex(of: quote) {
                            let value = String(remaining[..<endQuote])
                            attributes[name] = value
                            remaining = remaining[remaining.index(after: endQuote)...]
                        }
                    } else {
                        var valueEnd = remaining.startIndex
                        while valueEnd < remaining.endIndex && !remaining[valueEnd].isWhitespace {
                            valueEnd = remaining.index(after: valueEnd)
                        }
                        let value = String(remaining[remaining.startIndex..<valueEnd])
                        attributes[name] = value
                        remaining = remaining[valueEnd...]
                    }
                } else {
                    attributes[name] = ""
                }
            }

            return attributes
        }

        /// Extract content between opening and closing tags
        private static func extractElementContent(
            html: String,
            from startIndex: String.Index,
            tagName: String
        ) -> (String, String.Index)? {
            var depth = 1
            var index = startIndex
            let openTag = "<\(tagName)"
            let closeTag = "</\(tagName)>"

            while index < html.endIndex && depth > 0 {
                let remaining = html[index...]

                if remaining.hasPrefix(closeTag) {
                    depth -= 1
                    if depth == 0 {
                        let content = String(html[startIndex..<index])
                        let endIndex = html.index(index, offsetBy: closeTag.count)
                        return (content, endIndex)
                    }
                    index = html.index(index, offsetBy: closeTag.count)
                } else if remaining.hasPrefix(openTag) {
                    let afterTag = html.index(index, offsetBy: openTag.count)
                    if afterTag < html.endIndex {
                        let nextChar = html[afterTag]
                        if nextChar == " " || nextChar == ">" {
                            depth += 1
                        }
                    }
                    index = html.index(after: index)
                } else {
                    index = html.index(after: index)
                }
            }

            return nil
        }

        /// Check if tag is a void element
        private static func isVoidElement(_ tagName: String) -> Bool {
            let voidElements: Set<String> = [
                "area", "base", "br", "col", "embed", "hr", "img", "input",
                "link", "meta", "param", "source", "track", "wbr"
            ]
            return voidElements.contains(tagName)
        }

        // MARK: - Element Dispatch

        /// Handle void elements by dispatching to element-specific methods
        private static func handleVoidElement(
            _ tagName: String,
            attributes: [String: String],
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> (any PDF.View)? {
            switch tagName {
            case BR.tag:
                return BR.toPDF(configuration: configuration, style: style)
            case ThematicBreak.tag:
                return ThematicBreak.toPDF(configuration: configuration, style: style)
            default:
                return nil
            }
        }

        /// Convert element by dispatching to element-specific methods
        private static func convertElement(
            tagName: String,
            content: String,
            attributes: [String: String],
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> (any PDF.View)? {
            switch tagName {
            // Headings
            case H1.tag:
                return H1.toPDF(content: content, configuration: configuration, style: style)
            case H2.tag:
                return H2.toPDF(content: content, configuration: configuration, style: style)
            case H3.tag:
                return H3.toPDF(content: content, configuration: configuration, style: style)
            case H4.tag:
                return H4.toPDF(content: content, configuration: configuration, style: style)
            case H5.tag:
                return H5.toPDF(content: content, configuration: configuration, style: style)
            case H6.tag:
                return H6.toPDF(content: content, configuration: configuration, style: style)

            // Block elements
            case ContentDivision.tag:
                return ContentDivision.toPDF(content: content, configuration: configuration, style: style)
            case Section.tag:
                return Section.toPDF(content: content, configuration: configuration, style: style)
            case Article.tag:
                return Article.toPDF(content: content, configuration: configuration, style: style)
            case Header.tag:
                return Header.toPDF(content: content, configuration: configuration, style: style)
            case Footer.tag:
                return Footer.toPDF(content: content, configuration: configuration, style: style)
            case Main.tag:
                return Main.toPDF(content: content, configuration: configuration, style: style)
            case Aside.tag:
                return Aside.toPDF(content: content, configuration: configuration, style: style)
            case NavigationSection.tag:
                return NavigationSection.toPDF(content: content, configuration: configuration, style: style)

            case Paragraph.tag:
                return Paragraph.toPDF(content: content, configuration: configuration, style: style)

            // Inline formatting
            case B.tag:
                return B.toPDF(content: content, configuration: configuration, style: style)
            case StrongImportance.tag:
                return StrongImportance.toPDF(content: content, configuration: configuration, style: style)
            case IdiomaticText.tag:
                return IdiomaticText.toPDF(content: content, configuration: configuration, style: style)
            case Emphasis.tag:
                return Emphasis.toPDF(content: content, configuration: configuration, style: style)
            case ContentSpan.tag:
                return ContentSpan.toPDF(content: content, configuration: configuration, style: style)

            // Lists
            case UnorderedList.tag:
                return UnorderedList.toPDF(content: content, configuration: configuration, style: style)
            case OrderedList.tag:
                return OrderedList.toPDF(content: content, configuration: configuration, style: style)
            case ListItem.tag:
                return ListItem.toPDF(content: content, configuration: configuration, style: style)

            // Code
            case PreformattedText.tag:
                return PreformattedText.toPDF(content: content, configuration: configuration, style: style)
            case Code.tag:
                return Code.toPDF(content: content, configuration: configuration, style: style)

            // Quote
            case BlockQuote.tag:
                return BlockQuote.toPDF(content: content, configuration: configuration, style: style)

            default:
                // Default: treat as text container
                let trimmed = String(content.trimming(where: \.isWhitespace))
                if !trimmed.isEmpty {
                    return convertHTMLString(content, configuration: configuration, style: style)
                }
                return nil
            }
        }

        // MARK: - Text View Helper

        /// Create a text view with the given style
        static func createTextView(
            _ text: String,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> PDF.Text {
            PDF.Text(
                text,
                font: PDF.Font(style, base: configuration.defaultFont),
                fontSize: style.fontSize ?? configuration.defaultFontSize,
                color: style.color ?? configuration.defaultColor
            )
        }
    }
}
