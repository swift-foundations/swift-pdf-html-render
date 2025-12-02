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
                // Flush any pending inline runs before this block
                // (flushInlineRuns adds operations directly to context)
                let _ = context.flushInlineRuns()

                // Check for page break before adding spacing
                if beforeSpacing > 0 {
                    context.checkPageBreak(needing: beforeSpacing)
                    context.advanceY(beforeSpacing)
                }

                // Render children (which may accumulate inline runs or add ops to context)
                let _ = renderContent(with: childStyle)

                // Flush inline runs accumulated by children
                let _ = context.flushInlineRuns()

                // Add spacing after
                if afterSpacing > 0 {
                    context.advanceY(afterSpacing)
                }

                // Return empty - all operations are in context for pagination
                return PDF.Content()
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
                    beforeSpacing: headingSize * 1.0,  // Full line before H1
                    afterSpacing: headingSize * 0.5    // Half line after
                )

            case "h2":
                let headingSize = configuration.headingSize(level: 2)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.9,  // Nearly full line before H2
                    afterSpacing: headingSize * 0.4
                )

            case "h3":
                let headingSize = configuration.headingSize(level: 3)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.8,
                    afterSpacing: headingSize * 0.35
                )

            case "h4":
                let headingSize = configuration.headingSize(level: 4)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.7,
                    afterSpacing: headingSize * 0.3
                )

            case "h5":
                let headingSize = configuration.headingSize(level: 5)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.6,
                    afterSpacing: headingSize * 0.25
                )

            case "h6":
                let headingSize = configuration.headingSize(level: 6)
                let headingStyle = style.merging(HTML.ComputedStyle(
                    fontSize: headingSize,
                    fontWeight: .bold
                ))
                return renderBlock(
                    with: headingStyle,
                    beforeSpacing: headingSize * 0.5,
                    afterSpacing: headingSize * 0.2
                )

            // MARK: - Paragraph (Block)

            case "p":
                return renderBlock(
                    with: style,
                    afterSpacing: fontSize * 0.8  // More space between paragraphs
                )

            // MARK: - Inline Formatting (NO flush)

            case "strong", "b":
                let boldStyle = style.merging(HTML.ComputedStyle(fontWeight: .bold))
                return renderContent(with: boldStyle)

            case "em", "i":
                let italicStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))
                return renderContent(with: italicStyle)

            case "code":
                // Use Courier font for inline code
                let codeStyle = style.merging(HTML.ComputedStyle(
                    fontSize: fontSize * 0.9,
                    fontFamily: .courier
                ))
                return renderContent(with: codeStyle)

            case "span", "a", "small", "mark", "sub", "sup", "s", "u":
                // Inline elements - just pass through with same style
                return renderContent(with: style)

            // MARK: - Preformatted (Block)

            case "pre":
                // Preformatted text uses Courier font
                let preStyle = style.merging(HTML.ComputedStyle(
                    fontSize: fontSize * 0.85,
                    fontFamily: .courier
                ))

                // Flush any pending inline runs before this block
                let _ = context.flushInlineRuns()

                // Add spacing and indentation for code blocks
                context.checkPageBreak(needing: fontSize * 0.5)
                context.advanceY(fontSize * 0.5)

                let originalX = context.x
                let indent: Double = 20
                context.x += indent
                context.availableWidth -= indent

                // Enable preformatted mode to preserve whitespace/newlines
                let wasPreserving = context.preserveWhitespace
                context.preserveWhitespace = true

                // Render content
                let _ = renderContent(with: preStyle)

                // Flush inline runs accumulated by children
                let _ = context.flushInlineRuns()

                // Restore preformatted mode
                context.preserveWhitespace = wasPreserving

                // Restore position and add spacing after
                context.x = originalX
                context.availableWidth += indent
                context.advanceY(fontSize * 0.5)

                return PDF.Content()

            // MARK: - Block Containers

            case "div":
                return renderBlock(with: style)

            case "section", "article":
                // Sections and articles get extra spacing
                return renderBlock(
                    with: style,
                    beforeSpacing: fontSize * 0.5,
                    afterSpacing: fontSize * 0.5
                )

            case "header":
                return renderBlock(
                    with: style,
                    afterSpacing: fontSize * 0.5
                )

            case "footer":
                return renderBlock(
                    with: style,
                    beforeSpacing: fontSize * 1.0
                )

            case "main", "aside", "nav":
                return renderBlock(with: style)

            // MARK: - Void Elements

            case "br":
                // Line break - flush current inline runs first
                let _ = context.flushInlineRuns()
                context.checkPageBreak(needing: fontSize)
                context.advanceY(fontSize)
                return PDF.Content()

            case "hr":
                // Flush any pending runs
                let _ = context.flushInlineRuns()

                // Add spacing before
                context.checkPageBreak(needing: fontSize * 0.5)
                context.advanceY(fontSize * 0.5)

                // Add horizontal rule line
                let lineOps = PDF.Divider(
                    color: style.color ?? .gray50,
                    thickness: 1,
                    padding: 0
                ).render(context: &context)
                context.addOperations(lineOps.operations)

                // Add spacing after
                context.advanceY(fontSize * 0.5)
                return PDF.Content()

            // MARK: - Blockquote (Block)

            case "blockquote":
                // Blockquotes get left indent and italic styling
                let quoteStyle = style.merging(HTML.ComputedStyle(fontStyle: .italic))

                // Flush any pending inline runs before this block
                let _ = context.flushInlineRuns()

                // Add spacing before
                context.checkPageBreak(needing: fontSize * 0.5)
                context.advanceY(fontSize * 0.5)

                // Indent blockquote content
                let originalX = context.x
                let indent: Double = 30
                context.x += indent
                context.availableWidth -= indent

                // Render children
                let _ = convertToPDF(
                    content,
                    configuration: configuration,
                    style: quoteStyle,
                    context: &context
                )

                // Flush inline runs accumulated by children
                let _ = context.flushInlineRuns()

                // Restore position and add spacing after
                context.x = originalX
                context.availableWidth += indent
                context.advanceY(fontSize * 0.5)

                return PDF.Content()

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

            // Flush pending runs before list
            let _ = context.flushInlineRuns()

            // Push unordered list context
            context.pushList(.unordered)

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let bulletIndent: Double = 20
            let originalX = context.x

            // Indent for list content
            context.x += bulletIndent
            context.availableWidth -= bulletIndent

            // Render list content (operations go to context)
            let _ = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )

            // Flush any remaining runs
            let _ = context.flushInlineRuns()

            // Pop list context
            context.popList()

            // Restore position
            context.x = originalX
            context.availableWidth += bulletIndent
            context.advanceY(fontSize * 0.25)

            return PDF.Content()
        }

        private static func renderOrderedList<Content: HTML.View>(
            content: Content?,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle,
            context: inout PDF.Context
        ) -> PDF.Content {
            guard let content = content else { return PDF.Content() }

            // Flush pending runs before list
            let _ = context.flushInlineRuns()

            // Push ordered list context (starting at 1)
            context.pushList(.ordered(startNumber: 1))

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let numberIndent: Double = 25
            let originalX = context.x

            // Indent for list content
            context.x += numberIndent
            context.availableWidth -= numberIndent

            // Render list content (operations go to context)
            let _ = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )

            // Flush any remaining runs
            let _ = context.flushInlineRuns()

            // Pop list context
            context.popList()

            // Restore position
            context.x = originalX
            context.availableWidth += numberIndent
            context.advanceY(fontSize * 0.25)

            return PDF.Content()
        }

        private static func renderListItem<Content: HTML.View>(
            content: Content?,
            configuration: HTML.Configuration,
            style: HTML.ComputedStyle,
            context: inout PDF.Context
        ) -> PDF.Content {
            guard let content = content else { return PDF.Content() }

            // Flush pending runs
            let _ = context.flushInlineRuns()

            let fontSize = style.fontSize ?? configuration.defaultFontSize
            let font = PDF.Font(style, base: configuration.defaultFont)
            let color = style.color ?? configuration.defaultColor

            // Check for page break before rendering marker
            context.checkPageBreak(needing: fontSize)

            // Get the list marker (-, 1., 2., etc.) from context
            let marker = context.nextListMarker()

            // Calculate marker position to the left of indented content
            // For numbered lists, we need more space for wider markers like "10."
            let markerWidth = font.stringWidth(marker, atSize: fontSize)
            let markerX = context.x - markerWidth - 4  // 4pt gap between marker and content
            context.addOperation(.text(PDF.TextOperation(
                text: marker,
                position: PDF.Point(x: markerX, y: context.y),
                font: font,
                size: fontSize,
                color: color
            )))

            // Render list item content (operations go to context)
            let _ = convertToPDF(
                content,
                configuration: configuration,
                style: style,
                context: &context
            )

            // Flush runs from list item content
            let _ = context.flushInlineRuns()

            // Add spacing between items
            context.advanceY(fontSize * 0.3)

            return PDF.Content()
        }
    }
}
