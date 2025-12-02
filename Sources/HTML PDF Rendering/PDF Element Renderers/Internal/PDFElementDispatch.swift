// PDFElementDispatch.swift
// Centralized dispatch for HTML element PDF rendering

import PDF_Rendering
import HTML_Standard

/// Dispatches HTML element rendering based on tag name.
/// This replaces the registry-based lookup with direct static dispatch.
internal func dispatchElementRender(
    tag: String,
    attributes: [String: String],
    children: [any HTMLToPDFConvertible],
    style: HTML.ComputedStyle,
    context: inout PDF.Context,
    configuration: HTML.Configuration
) throws {
    switch tag.lowercased() {
    // Void/Simple elements
    case "br":
        try BR.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "hr":
        try ThematicBreak.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Headings
    case "h1":
        try H1.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "h2":
        try H2.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "h3":
        try H3.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "h4":
        try H4.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "h5":
        try H5.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "h6":
        try H6.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Text formatting - block
    case "p":
        try Paragraph.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "pre":
        try PreformattedText.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "blockquote":
        try BlockQuote.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Text formatting - inline
    case "strong":
        try StrongImportance.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "b":
        try B.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "em":
        try Emphasis.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "i":
        try IdiomaticText.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "u":
        try UnarticulatedAnnotation.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "s":
        try Strikethrough.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "code":
        try Code.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "mark":
        try Mark.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "small":
        try Small.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "sub":
        try Subscript.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "sup":
        try Superscript.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Containers
    case "div":
        try ContentDivision.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "span":
        try ContentSpan.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "section":
        try Section.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "article":
        try Article.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "header":
        try Header.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "footer":
        try Footer.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "main":
        try Main.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "aside":
        try Aside.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "nav":
        try NavigationSection.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Links
    case "a":
        try Anchor.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Lists
    case "ul":
        try UnorderedList.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "ol":
        try OrderedList.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "li":
        try ListItem.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Tables
    case "table":
        try Table.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "thead":
        try TableHead.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "tbody":
        try TableBody.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "tfoot":
        try TableFoot.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "tr":
        try TableRow.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "th":
        try TableHeader.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "td":
        try TableDataCell.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "caption":
        try Caption.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Media
    case "img":
        try Image.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "figure":
        try Figure.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "figcaption":
        try FigureCaption.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "picture":
        try Picture.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Forms
    case "form":
        try Form.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "input":
        try Input.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "button":
        try Button.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "select":
        try Select.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "option":
        try Option.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "textarea":
        try Textarea.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "label":
        try Label.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "fieldset":
        try FieldSet.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "legend":
        try Legend.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Interactive
    case "details":
        try Details.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "summary":
        try DisclosureSummary.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)
    case "dialog":
        try Dialog.Renderer.render(tag: tag, attributes: attributes, children: children, style: style, context: &context, configuration: configuration)

    // Default: render children as block
    default:
        try renderBlock(
            children: children,
            style: style,
            context: &context,
            configuration: configuration
        )
    }
}
