import Render_Primitives

extension PDF.HTML.Context.Table.Recording {

    enum Command: @unchecked Sendable {

        case text(String)
        case lineBreak
        case thematicBreak
        case image(source: String, alt: String)
        case pageBreak

        case setAttribute(name: String, value: String?)
        case addClass(String)
        case writeRaw([UInt8])

        case inlineStyle(Any)

        case pushBlock(
            role: Render_Primitives.Render.Semantic.Block?,
            style: Render_Primitives.Render.Style
        )
        case popBlock
        case pushInline(
            role: Render_Primitives.Render.Semantic.Inline?,
            style: Render_Primitives.Render.Style
        )
        case popInline
        case pushList(kind: Render_Primitives.Render.Semantic.List, start: Int?)
        case popList
        case pushItem
        case popItem
        case pushLink(destination: String)
        case popLink
        case pushAttributes
        case popAttributes
        case pushElement(tagName: String, isBlock: Bool, isVoid: Bool, isPreElement: Bool)
        case popElement(isBlock: Bool)
        case pushStyle
        case popStyle
    }
}
