// PDF.HTML.Context.Table.Recording.Command.swift
// Recorded rendering operation for first-row replay

import Render_Primitives

extension PDF.HTML.Context.Table.Recording {
    /// A single rendering operation recorded during first-row measurement.
    // WHY: Category D — structural Sendable workaround.
    // WHY: `inlineStyle(Any)` case stores CSS property values that are value
    // WHY: types but not formally Sendable. `Any` existential blocks inference.
    // WHY: No caller invariant to uphold — data is pure value bytes.
    // WHEN TO REMOVE: When the Any case is replaced with typed CSS properties.
    // TRACKING: unsafe-audit-findings.md Category D; SP-7.
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
        case pushBlock(role: Render.Semantic.Block?, style: Render.Style)
        case popBlock
        case pushInline(role: Render.Semantic.Inline?, style: Render.Style)
        case popInline
        case pushList(kind: Render.Semantic.List, start: Int?)
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
