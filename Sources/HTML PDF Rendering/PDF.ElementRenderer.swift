// PDF.ElementRenderer.swift

import HTML_Renderable
import PDF_Rendering

extension PDF {
    /// Consolidated renderer for HTML elements to PDF.
    ///
    /// This enum contains all tag-specific rendering logic, replacing
    /// the 23 separate Element files.
    ///
    /// Key concept: Block elements flush accumulated inline text runs,
    /// while inline elements only modify style and continue accumulating.
    public enum ElementRenderer {

        /// Check if a tag is an inline element (doesn't flush text runs).
        ///
        /// Inline elements modify styling but continue inline text flow.
        /// Block elements flush accumulated text before and after.
        public static func isInlineTag(_ tag: String) -> Bool {
            switch tag.lowercased() {
            case "strong", "b", "em", "i", "code", "span", "a", "small", "mark", "sub", "sup", "s", "u":
                return true
            default:
                return false
            }
        }

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

            /// Render child content with given style
            func renderContent(with childStyle: HTML.ComputedStyle) -> PDF.Content {
                guard let content = content else { return PDF.Content() }
                return convertToPDF(
                    content,
                    configuration: configuration,
                    style: childStyle,
                    context: &context
                )
            }

            /// Render as a block element: flush runs before and after, with spacing
            func renderBlock(
                with childStyle: HTML.ComputedStyle,
                beforeSpacing: Double = 0,
                afterSpacing: Double = 0
            ) -> PDF.Content {
                var operations: [PDF.Operation] = []

                // Flush any pending inline runs before this block
                let beforeFlush = context.flushInlineRuns()
                operations.append(contentsOf: beforeFlush.operations)

                // Add spacing before
                if beforeSpacing > 0 {
                    context.advanceY(beforeSpacing)
                }

                // Render children (which may accumulate inline runs)
                let childResult = renderContent(with: childStyle)
                operations.append(contentsOf: childResult.operations)

                // Flush inline runs accumulated by children
                let afterFlush = context.flushInlineRuns()
                operations.append(contentsOf: afterFlush.operations)

                // Add spacing after
                if afterSpacing > 0 {
                    context.advanceY(afterSpacing)
                }

                return PDF.Content(operations: operations)
            }

            let fontSize = style.fontSize ?? configuration.defaultFontSize

            switch tag.lowercased() {
            // MARK: - Headings (Block)

            case "h1":
                let headingSize = configuration.headingSize(level: 1)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.5,
                    afterSpacing: headingSize * 0.25
                )

            case "h2":
                let headingSize = configuration.headingSize(level: 2)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.4,
                    afterSpacing: headingSize * 0.2
                )

            case "h3":
                let headingSize = configuration.headingSize(level: 3)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.3,
                    afterSpacing: headingSize * 0.15
                )

            case "h4":
                let headingSize = configuration.headingSize(level: 4)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.25,
                    afterSpacing: headingSize * 0.125
                )

            case "h5":
                let headingSize = configuration.headingSize(level: 5)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.2,
                    afterSpacing: headingSize * 0.1
                )

            case "h6":
                let headingSize = configuration.headingSize(level: 6)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.15,
                    afterSpacing: headingSize * 0.075
                )

            // MARK: - Paragraph (Block)

            case "p":
                return renderBlock(
                    with: style,
                    afterSpacing: fontSize * 0.5
                )

            // MARK: - Inline Formatting (NO flush)

            case "strong", "b":
                let boldStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
                return renderContent(with: boldStyle)

            case "em", "i":
                let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
                return renderContent(with: italicStyle)

            case "code":
                // Code uses monospace, but we don't have courier mapping yet
                // Just reduce size slightly for now
                let codeStyle = style.merging(HTML.ComputedStyle(
                    fontSize: fontSize * 0.9
                ))
                return renderContent(with: codeStyle)

            case "span", "a", "small", "mark", "sub", "sup", "s", "u":
                // Inline elements - just pass through with same style
                return renderContent(with: style)

            // MARK: - Preformatted (Block)

            case "pre":
                let preStyle = style.merging(HTML.ComputedStyle(
                    fontSize: fontSize * 0.9
                ))
                return renderBlock(
                    with: preStyle,
                    afterSpacing: fontSize * 0.5
                )

            // MARK: - Block Containers

            case "div", "section", "article", "header", "footer", "main", "aside", "nav":
                return renderBlock(with: style)

            // MARK: - Void Elements

            case "br":
                // Line break - flush current inline runs first
                var operations: [PDF.Operation] = []
                operations.append(contentsOf: context.flushInlineRuns().operations)
                operations.append(contentsOf: PDF.Spacer(fontSize).render(context: &context).operations)
                return PDF.Content(operations: operations)

            case "hr":
                var operations: [PDF.Operation] = []
                // Flush any pending runs
                operations.append(contentsOf: context.flushInlineRuns().operations)
                operations.append(contentsOf: PDF.Spacer(fontSize * 0.5).render(context: &context).operations)
                operations.append(contentsOf: PDF.Divider(
                    color: style.color ?? .gray50,
                    thickness: 1,
                    padding: 0
                ).render(context: &context).operations)
                operations.append(contentsOf: PDF.Spacer(fontSize * 0.5).render(context: &context).operations)
                return PDF.Content(operations: operations)

            // MARK: - Blockquote (Block)

            case "blockquote":
                let quoteStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
                return renderBlock(
                    with: quoteStyle,
                    beforeSpacing: fontSize * 0.5,
                    afterSpacing: fontSize * 0.5
                )

            // MARK: - Lists (Block)

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
                return renderListItem(
                    content: content,
                    configuration: configuration,
                    style: style,
                    context: &context
                )

            // MARK: - Default (Block)

            default:
                return renderBlock(with: style)
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
            var operations: [PDF.Operation] = []

            // Flush pending runs before list
            operations.append(contentsOf: context.flushInlineRuns().operations)

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let bulletIndent: Double = 20
            let originalX = context.x

            // Indent for list content
            context.x += bulletIndent
            context.availableWidth -= bulletIndent

            // Render list content
            let result = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )
            operations.append(contentsOf: result.operations)

            // Flush any remaining runs
            operations.append(contentsOf: context.flushInlineRuns().operations)

            // Restore position
            context.x = originalX
            context.availableWidth += bulletIndent
            context.advanceY(fontSize * 0.25)

            return PDF.Content(operations: operations)
        }

        private static func renderOrderedList<Content: HTML.View>(
            content: Content?,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle,
            context: inout PDF.Context
        ) -> PDF.Content {
            guard let content = content else { return PDF.Content() }
            var operations: [PDF.Operation] = []

            // Flush pending runs before list
            operations.append(contentsOf: context.flushInlineRuns().operations)

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let numberIndent: Double = 25
            let originalX = context.x

            // Indent for list content
            context.x += numberIndent
            context.availableWidth -= numberIndent

            // Render list content
            let result = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )
            operations.append(contentsOf: result.operations)

            // Flush any remaining runs
            operations.append(contentsOf: context.flushInlineRuns().operations)

            // Restore position
            context.x = originalX
            context.availableWidth += numberIndent
            context.advanceY(fontSize * 0.25)

            return PDF.Content(operations: operations)
        }

        private static func renderListItem<Content: HTML.View>(
            content: Content?,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle,
            context: inout PDF.Context
        ) -> PDF.Content {
            guard let content = content else { return PDF.Content() }
            var operations: [PDF.Operation] = []

            // Flush pending runs
            operations.append(contentsOf: context.flushInlineRuns().operations)

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let font = PDF.Font(style, base: configuration.defaultFont)
            let color = style.color ?? configuration.defaultColor

            // Render bullet point at the original margin
            // The bullet appears to the left of the indented content
            // Using hyphen-minus as bullet since "•" (U+2022) isn't in Standard 14 fonts
            let bulletX = context.x - 12  // Position bullet to the left
            operations.append(.text(PDF.TextOperation(
                text: "-",
                position: PDF.Point(x: bulletX, y: context.y),
                font: font,
                size: fontSize,
                color: color
            )))

            // Render list item content
            let _ = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )

            // Flush runs from list item content
            operations.append(contentsOf: context.flushInlineRuns().operations)

            // Add spacing between items
            context.advanceY(fontSize * 0.3)

            return PDF.Content(operations: operations)
        }
    }
}
