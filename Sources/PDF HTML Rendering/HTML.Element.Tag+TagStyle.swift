// HTML.Element.Tag+TagStyle.swift
// Tag-specific styling, block margins, and heading level detection

import HTML_Rendering_Core
import PDF_Rendering

extension HTML.Element.Tag {
    /// Apply tag-specific styling based on tag name
    static func applyTagStyle(_ tagName: String, context: inout PDF.HTML.Context) {
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
        // WebKit uses a smaller monospace font relative to body text
        case "code", "kbd", "samp":
            context.pdf.style.font = .courier
            // WebKit's monospace is slightly smaller than body text
            context.pdf.style.fontSize = (context.pdf.style.fontSize) * 0.9

        case "pre":
            context.pdf.style.font = .courier
            context.pdf.style.fontSize = (context.pdf.style.fontSize) * 0.9
            context.pdf.mode.preserveWhitespace = true

        // Text decoration
        case "s", "strike", "del":
            context.pdf.style.textMarkup = .strikeOut

        case "u", "ins":
            context.pdf.style.textMarkup = .underline

        case "mark":
            context.pdf.style.textMarkup = .highlight(.rgb(red: 1.0, green: 1.0, blue: 0.0))

        // Sub/superscript
        // WebKit: font-size ~0.83em, vertical-align: sub/super
        case "sub":
            let currentSize = context.pdf.style.fontSize
            context.pdf.style.fontSize =
                currentSize * context.configuration.typography.subscriptScale
            // Subscript drops below baseline
            context.pdf.style.verticalOffset -=
                (currentSize * context.configuration.typography.subscriptOffset).height

        case "sup":
            let currentSize = context.pdf.style.fontSize
            context.pdf.style.fontSize =
                currentSize * context.configuration.typography.superscriptScale
            // Superscript rises above baseline
            context.pdf.style.verticalOffset +=
                (currentSize * context.configuration.typography.superscriptOffset).height

        // Small - WebKit default is smaller
        case "small":
            // reason: no Size<1> *= Double compound-assignment overload; a = a * b is the
            // only expressible form (SIMD generic *= mis-resolution)
            // swiftlint:disable:next shorthand_operator
            context.pdf.style.fontSize =
                context.pdf.style.fontSize * context.configuration.typography.smallScale

        // Links
        case "a":
            context.pdf.style.color = .blue
            context.pdf.style.textMarkup = .underline

        // Block indentation
        // WebKit default margin-left for blockquote is 40px = 30pt (at 72/96 conversion)
        case "blockquote", "dd":
            let indent = context.configuration.indent.blockquote
            context.pdf.layout.box.llx += indent

        case "figure":
            let margin = context.configuration.indent.figure
            context.pdf.layout.box.llx += margin
            context.pdf.layout.box.urx -= margin

        // Citation, definition, and variable (all italic in WebKit)
        case "cite", "dfn", "var":
            context.pdf.style.font = context.pdf.style.font.italic

        default:
            break
        }
    }

    /// Get block margins for a tag name
    static func blockMargins(
        for tagName: String,
        configuration: PDF.HTML.Configuration
    ) -> (top: LengthPercentage, bottom: LengthPercentage)? {
        switch tagName {
        case "p":
            return (.length(.em(1.0)), .length(.em(1.0)))

        case "h1", "h2", "h3", "h4", "h5", "h6":
            let margin = configuration.headingMarginEm(for: tagName).value
            return (.length(.em(margin)), .length(.em(margin)))

        case "blockquote":
            return (.length(.em(1.0)), .length(.em(1.0)))

        // Note: <figure> has no vertical margins - its children provide spacing.
        // This matches WebKit behavior where figure acts as a transparent container
        // for margin collapsing, with only horizontal indentation applied.
        case "pre":
            return (.length(.em(1.0)), .length(.em(1.0)))

        case "ul", "ol":
            // Note: nested lists have no margins (handled by parent li element)
            return (.length(.em(1.0)), .length(.em(1.0)))

        // Note: <li> has no default margins per WHATWG HTML Standard
        // The parent <ul>/<ol> provides the 1em margins
        case "table":
            // WebKit / mainstream-UA default: table has no inherent vertical
            // margin (browsers rely on adjacent flow content's own margins).
            // CSS 2.1 §17 does not specify a default; aligning with the
            // de-facto W3C-evergreen UA stylesheet by returning nil so that
            // consumer-provided `.css.margin(top:bottom:)` is the sole
            // source of vertical spacing for tables.
            return nil

        default:
            return nil
        }
    }

    // MARK: - Heading Level Detection

    /// Get heading level for tag name (nil if not a heading)
    static func headingLevel(for tagName: String) -> Int? {
        switch tagName {
        case "h1": return 1
        case "h2": return 2
        case "h3": return 3
        case "h4": return 4
        case "h5": return 5
        case "h6": return 6
        default: return nil
        }
    }

    /// Check if tag is a list container
    static func isListContainer(_ tagName: String) -> Bool {
        tagName == "ol" || tagName == "ul"
    }

    /// Get list type for a list container tag
    static func listType(for tagName: String) -> PDF.Context.List.Kind? {
        switch tagName {
        case "ol": return .ordered(startNumber: 1)
        case "ul": return .unordered
        default: return nil
        }
    }
}
