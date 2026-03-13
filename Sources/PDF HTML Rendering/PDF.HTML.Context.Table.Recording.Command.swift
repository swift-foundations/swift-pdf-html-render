// PDF.HTML.Context.Table.Recording.Command.swift
// Recorded rendering operation for first-row replay

import Rendering_Primitives

extension PDF.HTML.Context.Table.Recording {
    /// A single rendering operation recorded during first-row measurement.
    ///
    /// Uses `@unchecked Sendable` because the `inlineStyle(Any)` case stores
    /// CSS property values that are value types but not formally Sendable.
    /// Recording is temporary and does not cross concurrency boundaries.
    enum Command: @unchecked Sendable {
        // Content
        case text(String)
        case lineBreak
        case thematicBreak
        case image(source: String, alt: String)
        case pageBreak

        // Attributes
        case setAttribute(name: String, value: String?)
        case addClass(String)
        case writeRaw([UInt8])

        // Inline style (Any boxes the CSS property value)
        case inlineStyle(Any)

        // Structure
        case pushBlock(role: Rendering.Semantic.Block?, style: Rendering.Style)
        case popBlock
        case pushInline(role: Rendering.Semantic.Inline?, style: Rendering.Style)
        case popInline
        case pushList(kind: Rendering.Semantic.List, start: Int?)
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
