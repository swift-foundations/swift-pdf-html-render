// HTML.Element+PDF.HTML.View.swift
// HTML.Element rendering using runtime tag metadata

import CSS_Standard
import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension HTML.Element: PDF.HTML.View where Content: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Handle void elements (br, hr, etc.) based on runtime check
        if view.isVoid {
            renderVoidElement(view, context: &context)
            return
        }

        // Determine if this is a block or inline element
        let isBlock = view.isBlock

        // Check for block margins
        let marginTop: PDF.UserSpace.Unit
        let marginBottom: PDF.UserSpace.Unit
        if let margins = blockMargins(for: view.tagName, configuration: context.configuration) {
            marginTop = PDF.UserSpace.Unit(
                margins.top,
                currentSize: context.pdf.style.fontSize,
                baseFontSize: context.configuration.defaultFontSize
            )
            marginBottom = PDF.UserSpace.Unit(
                margins.bottom,
                currentSize: context.pdf.style.fontSize,
                baseFontSize: context.configuration.defaultFontSize
            )
        } else {
            marginTop = 0
            marginBottom = 0
        }

        // If there's deferred content (from page-break-after: avoid) and we're rendering a block element
        if isBlock, let deferred = context.deferredKeepWithNextRender {
            // Clear deferred content - we're handling it now
            context.deferredKeepWithNextRender = nil

            // If the deferred header is very tall (> 90% of page), skip sticky behavior
            let availablePageHeight = context.pdf.remainingHeight
            if deferred.measuredHeight.value > availablePageHeight.value * 0.9 {
                // Just render the header without sticky behavior
                deferred.render(&context)
                renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, context: &context)
                return
            }

            // Calculate minimum content height (at least one line + top margin)
            let oneLineHeight = context.pdf.style.lineHeightPoints
            let minContentHeight = marginTop + oneLineHeight.value
            let totalNeeded = PDF.UserSpace.Height(deferred.measuredHeight.value + minContentHeight)

            // Check if header + minimum content fits on current page
            if context.pdf.wouldExceedPage(adding: totalNeeded) {
                // Start new page BEFORE rendering the header
                context.pdf.startNewPage()
            }

            // Now render the deferred header
            deferred.render(&context)

            // Continue with normal rendering of this element
            renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, context: &context)
            return
        }

        // Save current style and horizontal bounds (NOT Y position - that must advance)
        let savedStyle = context.pdf.style
        let savedLLX = context.pdf.layoutBox.llx
        let savedURX = context.pdf.layoutBox.urx
        let savedPreserveWhitespace = context.pdf.preserveWhitespace

        // Apply tag-specific style
        applyTagStyle(view.tagName, context: &context)

        // Render with flow and margins
        renderWithFlow(view, isBlock: isBlock, marginTop: marginTop, marginBottom: marginBottom, context: &context)

        // Restore style and horizontal bounds (Y position stays advanced)
        context.pdf.style = savedStyle
        context.pdf.layoutBox.llx = savedLLX
        context.pdf.layoutBox.urx = savedURX
        context.pdf.preserveWhitespace = savedPreserveWhitespace
    }

    /// Render void element (br, hr, etc.)
    private static func renderVoidElement(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        switch view.tagName {
        case "br":
            context.pdf.flushInlineRuns()
            context.pdf.advanceLine()
        case "hr":
            context.pdf.flushInlineRuns()
            let spacing = context.configuration.defaultFontSize * 0.5
            context.pdf.advance(PDF.UserSpace.Y(spacing))

            let lineY = context.pdf.layoutBox.lly
            let startX = context.pdf.layoutBox.llx
            let endX = PDF.UserSpace.X(startX.value + context.pdf.layoutBox.width.value)

            context.pdf.emitLine(
                from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
                to: PDF.UserSpace.Coordinate(x: endX, y: lineY),
                color: .gray(0.5),
                width: 1
            )

            context.pdf.advance(PDF.UserSpace.Y(spacing))
        default:
            // Other void elements have no PDF representation
            break
        }
    }

    /// Render with flow (block or inline) and margins
    private static func renderWithFlow(
        _ view: Self,
        isBlock: Bool,
        marginTop: PDF.UserSpace.Unit,
        marginBottom: PDF.UserSpace.Unit,
        context: inout PDF.HTML.Context
    ) {
        if isBlock {
            context.applyCollapsedMargin(top: marginTop, bottom: marginBottom)
            PDF.HTML.renderBlock(view.content, context: &context)
        } else {
            PDF.HTML.renderInline(view.content, context: &context)
        }
    }

    /// Apply tag-specific styling based on tag name
    private static func applyTagStyle(_ tagName: String, context: inout PDF.HTML.Context) {
        switch tagName {
        // Headings
        case "h1":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 1)
        case "h2":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 2)
        case "h3":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 3)
        case "h4":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 4)
        case "h5":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 5)
        case "h6":
            context.pdf.style.font = context.pdf.style.font.bold
            context.pdf.style.fontSize = context.configuration.headingSize(level: 6)

        // Emphasis and importance
        case "strong", "b":
            context.pdf.style.font = context.pdf.style.font.bold
        case "em", "i":
            context.pdf.style.font = context.pdf.style.font.italic

        // Code and preformatted
        case "code", "kbd", "samp", "var":
            context.pdf.style.font = .courier
        case "pre":
            context.pdf.style.font = .courier
            context.pdf.preserveWhitespace = true

        // Text decoration
        case "s", "strike", "del":
            context.pdf.style.textMarkup = .strikeout
        case "u", "ins":
            context.pdf.style.textMarkup = .underline
        case "mark":
            context.pdf.style.textMarkup = .highlight(PDF.Color.yellow)

        // Sub/superscript
        case "sub":
            context.pdf.style.fontSize = context.pdf.style.fontSize * 0.75
            context.pdf.style.verticalOffset = context.pdf.style.fontSize * -0.3
        case "sup":
            context.pdf.style.fontSize = context.pdf.style.fontSize * 0.75
            context.pdf.style.verticalOffset = context.pdf.style.fontSize * 0.5

        // Small
        case "small":
            context.pdf.style.fontSize = context.pdf.style.fontSize * 0.85

        // Links
        case "a":
            context.pdf.style.color = .blue
            context.pdf.style.textMarkup = .underline

        // Block indentation
        case "blockquote", "dd":
            let indent: PDF.UserSpace.Unit = 40
            context.pdf.layoutBox.llx = PDF.UserSpace.X(context.pdf.layoutBox.llx.value + indent)
        case "figure":
            let margin: PDF.UserSpace.Unit = 40
            context.pdf.layoutBox.llx = PDF.UserSpace.X(context.pdf.layoutBox.llx.value + margin)
            context.pdf.layoutBox.urx = PDF.UserSpace.X(context.pdf.layoutBox.urx.value - margin)

        // Citation and definition
        case "cite", "dfn":
            context.pdf.style.font = context.pdf.style.font.italic

        default:
            break
        }
    }

    /// Get block margins for a tag name
    private static func blockMargins(
        for tagName: String,
        configuration: PDF.HTML.Configuration
    ) -> (top: LengthPercentage, bottom: LengthPercentage)? {
        switch tagName {
        case "p":
            return (.length(.em(1.0)), .length(.em(1.0)))
        case "h1":
            return (.length(.em(0.67)), .length(.em(0.67)))
        case "h2":
            return (.length(.em(0.83)), .length(.em(0.83)))
        case "h3":
            return (.length(.em(1.0)), .length(.em(1.0)))
        case "h4":
            return (.length(.em(1.33)), .length(.em(1.33)))
        case "h5":
            return (.length(.em(1.67)), .length(.em(1.67)))
        case "h6":
            return (.length(.em(2.33)), .length(.em(2.33)))
        case "blockquote", "figure":
            return (.length(.em(1.0)), .length(.em(1.0)))
        case "ul", "ol":
            return (.length(.em(1.0)), .length(.em(1.0)))
        default:
            return nil
        }
    }
}
