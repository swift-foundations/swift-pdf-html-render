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
        static func convertHTMLString(
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

        /// Parse tag name from tag content
        private static func parseTagName(_ tagContent: String) -> String {
            let content = String(tagContent.trimming(where: \.isWhitespace))
            if let spaceIndex = content.firstIndex(of: " ") {
                return String(content[..<spaceIndex]).lowercased()
            }
            return content.lowercased()
        }

        /// Parse attributes from tag content (simple parser without regex)
        private static func parseAttributes(_ tagContent: String) -> [String: String] {
            var attributes: [String: String] = [:]

            // Skip tag name
            guard let spaceIndex = tagContent.firstIndex(of: " ") else {
                return attributes
            }

            var remaining = tagContent[tagContent.index(after: spaceIndex)...]

            while !remaining.isEmpty {
                // Skip whitespace
                remaining = remaining.drop(while: \.isWhitespace)
                guard !remaining.isEmpty else { break }

                // Find attribute name
                var nameEnd = remaining.startIndex
                while nameEnd < remaining.endIndex && remaining[nameEnd] != "=" && !remaining[nameEnd].isWhitespace {
                    nameEnd = remaining.index(after: nameEnd)
                }

                let name = String(remaining[remaining.startIndex..<nameEnd])
                guard !name.isEmpty else { break }

                remaining = remaining[nameEnd...]

                // Skip whitespace and equals sign
                remaining = remaining.drop(while: \.isWhitespace)

                if remaining.first == "=" {
                    remaining = remaining.dropFirst()
                    remaining = remaining.drop(while: \.isWhitespace)

                    // Get value
                    if remaining.first == "\"" || remaining.first == "'" {
                        let quote = remaining.first!
                        remaining = remaining.dropFirst()
                        if let endQuote = remaining.firstIndex(of: quote) {
                            let value = String(remaining[..<endQuote])
                            attributes[name] = value
                            remaining = remaining[remaining.index(after: endQuote)...]
                        }
                    } else {
                        // Unquoted value - find end
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
                    // Check if it's actually an open tag (not just matching prefix)
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

        /// Handle void elements (br, hr, etc.)
        private static func handleVoidElement(
            _ tagName: String,
            attributes: [String: String],
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> (any PDF.View)? {
            switch tagName {
            case "br":
                return PDF.Spacer(style.fontSize ?? configuration.defaultFontSize)
            case "hr":
                return PDF.Divider()
            default:
                return nil
            }
        }

        /// Convert a specific HTML element to PDF view
        private static func convertElement(
            tagName: String,
            content: String,
            attributes: [String: String],
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> (any PDF.View)? {
            switch tagName {
            // Headings
            case "h1":
                return createHeading(level: 1, content: content, configuration: configuration, style: style)
            case "h2":
                return createHeading(level: 2, content: content, configuration: configuration, style: style)
            case "h3":
                return createHeading(level: 3, content: content, configuration: configuration, style: style)
            case "h4":
                return createHeading(level: 4, content: content, configuration: configuration, style: style)
            case "h5":
                return createHeading(level: 5, content: content, configuration: configuration, style: style)
            case "h6":
                return createHeading(level: 6, content: content, configuration: configuration, style: style)

            // Block elements
            case "div", "section", "article", "header", "footer", "main", "aside", "nav":
                return convertHTMLString(content, configuration: configuration, style: style)

            case "p":
                return createParagraph(content: content, configuration: configuration, style: style)

            // Inline formatting
            case "b", "strong":
                let boldStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
                return convertHTMLString(content, configuration: configuration, style: boldStyle)

            case "i", "em":
                let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
                return convertHTMLString(content, configuration: configuration, style: italicStyle)

            case "span":
                return convertHTMLString(content, configuration: configuration, style: style)

            // Lists
            case "ul", "ol":
                return createList(content: content, ordered: tagName == "ol", configuration: configuration, style: style)

            case "li":
                return createListItem(content: content, configuration: configuration, style: style)

            // Other
            case "pre", "code":
                let monoStyle = style.merging(HTML.ComputedStyle(fontSize: style.fontSize ?? configuration.defaultFontSize * 0.9))
                return convertHTMLString(content, configuration: configuration, style: monoStyle)

            case "blockquote":
                let quoteStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
                return convertHTMLString(content, configuration: configuration, style: quoteStyle)

            default:
                // Default: treat as text container
                let trimmed = String(content.trimming(where: \.isWhitespace))
                if !trimmed.isEmpty {
                    return convertHTMLString(content, configuration: configuration, style: style)
                }
                return nil
            }
        }

        /// Create a text view with the given style
        private static func createTextView(
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

        /// Create a heading view
        private static func createHeading(
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

            let childView = convertHTMLString(content, configuration: configuration, style: headingStyle)
            let spacing = headingSize * 0.5
            return PDF.VStack(spacing: 0, children: [
                PDF.Spacer(spacing),
                childView,
                PDF.Spacer(spacing * 0.5)
            ])
        }

        /// Create a paragraph view
        private static func createParagraph(
            content: String,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> any PDF.View {
            let childView = convertHTMLString(content, configuration: configuration, style: style)
            let spacing = (style.fontSize ?? configuration.defaultFontSize) * 0.5
            return PDF.VStack(spacing: 0, children: [
                childView,
                PDF.Spacer(spacing)
            ])
        }

        /// Create a list view
        private static func createList(
            content: String,
            ordered: Bool,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> any PDF.View {
            // Extract list items and number them
            var items: [any PDF.View] = []
            var itemIndex = 0

            var remaining = content[...]
            while let liStart = remaining.range(of: "<li") {
                // Find the end of opening tag
                if let tagEnd = remaining[liStart.upperBound...].firstIndex(of: ">") {
                    let afterTag = remaining.index(after: tagEnd)

                    // Find closing </li>
                    if let closeStart = remaining[afterTag...].range(of: "</li>") {
                        let itemContent = String(remaining[afterTag..<closeStart.lowerBound])
                        itemIndex += 1

                        let bullet = ordered ? "\(itemIndex). " : "• "
                        let trimmedContent = String(itemContent.trimming(where: \.isWhitespace))
                        let itemView = createTextView(
                            bullet + trimmedContent,
                            configuration: configuration,
                            style: style
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

        /// Create a list item view
        private static func createListItem(
            content: String,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle
        ) -> any PDF.View {
            let itemView = convertHTMLString(content, configuration: configuration, style: style)
            return itemView
        }

        /// Extract style from inline attributes
        private static func styleFromAttributes(_ attributes: [String: String]) -> HTML.ComputedStyle {
            var style = HTML.ComputedStyle.empty

            guard let styleAttr = attributes["style"] else {
                return style
            }

            // Parse inline style attribute
            let properties = styleAttr.split(separator: ";")
            for prop in properties {
                let parts = prop.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { continue }

                let name = String(parts[0].trimming(where: \.isWhitespace)).lowercased()
                let value = String(parts[1].trimming(where: \.isWhitespace)).lowercased()

                switch name {
                case "font-size":
                    style.fontSize = parseFontSize(value)
                case "color":
                    style.color = parseColor(value)
                case "font-weight":
                    if value == "bold" || value == "700" || value == "800" || value == "900" {
                        style.fontWeight = .bold
                    }
                case "font-style":
                    if value == "italic" || value == "oblique" {
                        style.fontStyle = .italic
                    }
                case "text-align":
                    style.textAlign = parseTextAlign(value)
                case "background-color", "background":
                    style.backgroundColor = parseColor(value)
                default:
                    break
                }
            }

            return style
        }

        /// Parse font size from CSS value
        private static func parseFontSize(_ value: String) -> Double? {
            let cleaned = String(value.trimming(where: \.isWhitespace))

            if cleaned.hasSuffix("px") {
                let number = cleaned.dropLast(2)
                return Double(number).map { $0 * 0.75 } // px to pt
            } else if cleaned.hasSuffix("pt") {
                let number = cleaned.dropLast(2)
                return Double(number)
            } else if cleaned.hasSuffix("em") {
                let number = cleaned.dropLast(2)
                return Double(number).map { $0 * 12 } // Assume 12pt base
            } else if cleaned.hasSuffix("%") {
                let number = cleaned.dropLast(1)
                return Double(number).map { $0 / 100 * 12 }
            }

            return Double(cleaned)
        }

        /// Parse color from CSS value
        private static func parseColor(_ value: String) -> PDF.Color? {
            let cleaned = String(value.trimming(where: \.isWhitespace)).lowercased()

            // Named colors
            switch cleaned {
            case "black": return .black
            case "white": return .white
            case "red": return .red
            case "green": return .rgb(r: 0, g: 0.5, b: 0)
            case "blue": return .blue
            case "gray", "grey": return .gray50
            default:
                break
            }

            // Hex colors
            if cleaned.hasPrefix("#") {
                return PDF.Color(hex: String(cleaned.dropFirst()))
            }

            // RGB/RGBA
            if cleaned.hasPrefix("rgb") {
                return parseRGBColor(cleaned)
            }

            return nil
        }

        /// Parse RGB/RGBA color (without Foundation)
        private static func parseRGBColor(_ value: String) -> PDF.Color? {
            // Extract numbers from rgb(r, g, b) or rgba(r, g, b, a)
            var numbers: [Double] = []
            var currentNumber = ""

            for char in value {
                if char.isNumber || char == "." {
                    currentNumber.append(char)
                } else if !currentNumber.isEmpty {
                    if let num = Double(currentNumber) {
                        numbers.append(num)
                    }
                    currentNumber = ""
                }
            }
            // Don't forget the last number
            if !currentNumber.isEmpty, let num = Double(currentNumber) {
                numbers.append(num)
            }

            guard numbers.count >= 3 else { return nil }

            let red = numbers[0] / 255.0
            let green = numbers[1] / 255.0
            let blue = numbers[2] / 255.0

            return .rgb(r: red, g: green, b: blue)
        }

        /// Parse text alignment
        private static func parseTextAlign(_ value: String) -> HTML.ComputedStyle.TextAlignment? {
            switch value.lowercased() {
            case "left": return .left
            case "center": return .center
            case "right": return .right
            case "justify": return .justify
            default: return nil
            }
        }
    }
}
