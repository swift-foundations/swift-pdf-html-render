// PDF.HTML.Context.Element.Scope.swift
// Saved state for element push/pop scoping

import PDF_Rendering
import W3C_CSS_Values

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
        /// Marker for void elements (e.g. `<br>`, `<hr>`, `<img>`). Void
        /// pushes don't change per-scope state; void pops therefore skip
        /// state restoration to keep `elementStack` balanced with the
        /// Render contract's symmetric `push.element`/`pop.element` calls.
        let isVoid: Bool
        /// Per-side border declarations captured from CSS modifiers
        /// (`border-top`/`border-right`/`border-bottom`/`border-left` and their
        /// longhand siblings). Rendered at element pop time per CSS
        /// Backgrounds 3 §3. `nil` = no border declared on that side.
        var pendingBorderTop: PendingSideBorder? = nil
        var pendingBorderRight: PendingSideBorder? = nil
        var pendingBorderBottom: PendingSideBorder? = nil
        var pendingBorderLeft: PendingSideBorder? = nil
    }
}

extension PDF.HTML.Context.Element.Scope {
    /// A border declaration captured from a per-side CSS modifier and
    /// pending render at element pop time.
    ///
    /// `style` carries the CSS `border-style` for the side. The renderer
    /// only honors `.solid` and `.double` today; other styles fall back to
    /// `.solid` per the institute's current line-shape policy.
    public struct PendingSideBorder: Sendable {
        public let width: PDF.UserSpace.Size<1>
        public let style: W3C_CSS_Values.LineStyle
        public let color: PDF.Color
    }
}
