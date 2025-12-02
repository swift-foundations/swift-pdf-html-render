// PDF.ElementRenderer.swift

import HTML_Renderable
import PDF_Rendering

extension PDF {
    /// Consolidated renderer for HTML elements to PDF.
    ///
    /// This enum contains all tag-specific rendering logic, replacing
    /// the 23 separate Element files.
    public enum ElementRenderer {

        /// Render an HTML element to PDF based on its tag.
        ///
        /// - Parameters:
        ///   - tag: The HTML tag name (e.g., "h1", "p", "strong")
        ///   - content: The element's content (if any)
        ///   - configuration: PDF conversion settings
        ///   - style: Current computed style
        ///   - context: Mutable PDF context
        /// - Returns: PDF content operations
        public static func render<Content: HTML.View>(
            tag: String,
            content: Content?,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle,
            context: inout PDF.Context
        ) -> PDF.Content {

            func renderContent(with childStyle: HTML.ComputedStyle) -> PDF.Content {
                guard let content = content else { return PDF.Content() }
                return convertToPDF(
                    content,
                    configuration: configuration,
                    style: childStyle,
                    context: &context
                )
            }

            let fontSize = style.fontSize ?? configuration.defaultFontSize

            switch tag.lowercased() {
            // MARK: - Headings

            case "h1":
                let headingSize = configuration.headingSize(level: 1)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                context.advanceY(headingSize * 0.5)
                let result = renderContent(with: headingStyle)
                context.advanceY(headingSize * 0.25)
                return result

            case "h2":
                let headingSize = configuration.headingSize(level: 2)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                context.advanceY(headingSize * 0.4)
                let result = renderContent(with: headingStyle)
                context.advanceY(headingSize * 0.2)
                return result

            case "h3":
                let headingSize = configuration.headingSize(level: 3)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                context.advanceY(headingSize * 0.3)
                let result = renderContent(with: headingStyle)
                context.advanceY(headingSize * 0.15)
                return result

            case "h4":
                let headingSize = configuration.headingSize(level: 4)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                context.advanceY(headingSize * 0.25)
                let result = renderContent(with: headingStyle)
                context.advanceY(headingSize * 0.125)
                return result

            case "h5":
                let headingSize = configuration.headingSize(level: 5)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                context.advanceY(headingSize * 0.2)
                let result = renderContent(with: headingStyle)
                context.advanceY(headingSize * 0.1)
                return result

            case "h6":
                let headingSize = configuration.headingSize(level: 6)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                context.advanceY(headingSize * 0.15)
                let result = renderContent(with: headingStyle)
                context.advanceY(headingSize * 0.075)
                return result

            // MARK: - Paragraph

            case "p":
                let result = renderContent(with: style)
                context.advanceY(fontSize * 0.5)
                return result

            // MARK: - Inline Formatting

            case "strong", "b":
                let boldStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
                return renderContent(with: boldStyle)

            case "em", "i":
                let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
                return renderContent(with: italicStyle)

            case "code":
                let codeStyle = style.merging(HTML.ComputedStyle(
                    fontSize: fontSize * 0.9
                ))
                return renderContent(with: codeStyle)

            case "pre":
                let preStyle = style.merging(HTML.ComputedStyle(
                    fontSize: fontSize * 0.9
                ))
                let result = renderContent(with: preStyle)
                context.advanceY(fontSize * 0.5)
                return result

            // MARK: - Block Containers

            case "div", "section", "article", "header", "footer", "main", "aside", "nav", "span":
                return renderContent(with: style)

            // MARK: - Void Elements

            case "br":
                return PDF.Spacer(fontSize).render(context: &context)

            case "hr":
                var operations: [PDF.Operation] = []
                operations.append(contentsOf: PDF.Spacer(fontSize * 0.5).render(context: &context).operations)
                operations.append(contentsOf: PDF.Divider(
                    color: style.color ?? .gray50,
                    thickness: 1,
                    padding: 0
                ).render(context: &context).operations)
                operations.append(contentsOf: PDF.Spacer(fontSize * 0.5).render(context: &context).operations)
                return PDF.Content(operations: operations)

            // MARK: - Blockquote

            case "blockquote":
                let quoteStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
                context.advanceY(fontSize * 0.5)
                let result = renderContent(with: quoteStyle)
                context.advanceY(fontSize * 0.5)
                return result

            // MARK: - Lists

            case "ul":
                return renderUnorderedList(
                    content: content,
                    configuration: configuration,
                    style: style,
                    context: &context
                )

            case "ol":
                return renderOrderedList(
                    content: content,
                    configuration: configuration,
                    style: style,
                    context: &context
                )

            case "li":
                return renderContent(with: style)

            // MARK: - Default

            default:
                return renderContent(with: style)
            }
        }

        // MARK: - List Rendering

        private static func renderUnorderedList<Content: HTML.View>(
            content: Content?,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle,
            context: inout PDF.Context
        ) -> PDF.Content {
            guard let content = content else { return PDF.Content() }

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let bulletIndent: Double = 20
            let originalX = context.x

            // Indent for list
            context.x += bulletIndent
            context.availableWidth -= bulletIndent

            let result = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )

            // Restore position
            context.x = originalX
            context.availableWidth += bulletIndent
            context.advanceY(fontSize * 0.25)

            return result
        }

        private static func renderOrderedList<Content: HTML.View>(
            content: Content?,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle,
            context: inout PDF.Context
        ) -> PDF.Content {
            guard let content = content else { return PDF.Content() }

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let numberIndent: Double = 25
            let originalX = context.x

            // Indent for list
            context.x += numberIndent
            context.availableWidth -= numberIndent

            let result = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )

            // Restore position
            context.x = originalX
            context.availableWidth += numberIndent
            context.advanceY(fontSize * 0.25)

            return result
        }
    }
}
