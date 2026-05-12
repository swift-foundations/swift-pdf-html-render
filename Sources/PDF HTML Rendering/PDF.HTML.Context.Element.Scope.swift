// PDF.HTML.Context.Element.Scope.swift
// Saved state for element push/pop scoping

import PDF_Rendering

extension PDF.HTML.Context.Element {
    /// Saved state captured by `_pushElement` and restored by `_popElement`.
    ///
    /// Captures style, layout X bounds, whitespace mode, and link state.
    /// Y position is NOT captured — it must advance through content rendering.
    public struct Scope {
        let tagName: String
        let isBlock: Bool
        let style: PDF.Context.Style.Resolved
        let llx: PDF.UserSpace.X
        let urx: PDF.UserSpace.X
        let preserveWhitespace: Bool
        let noWrap: Bool
        let linkURL: String?
        let internalLinkId: String?
        /// Saved table context (for "table" elements)
        let savedTable: PDF.HTML.Context.Table?
        /// Saved pending bottom margin (for list elements)
        let savedPendingMargin: PDF.UserSpace.Height
    }
}
