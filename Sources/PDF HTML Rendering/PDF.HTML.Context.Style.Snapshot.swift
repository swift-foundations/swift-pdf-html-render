// PDF.HTML.Context.Style.Snapshot.swift
// Scoped style and box model state for save/restore

extension PDF.HTML.Context.Style {
    /// Snapshot of style, box model, and layout X bounds for scoped restoration.
    ///
    /// Captures everything that `withSavedStyleState` needs to restore after
    /// running a closure: resolved style, margins, padding, explicit dimensions,
    /// and the horizontal bounds of the layout box. Y position is NOT captured
    /// — it must advance through content rendering.
    public struct Snapshot {
        let style: PDF.Context.Style.Resolved
        let margin: PDF.Context.Margin
        let padding: PDF.Context.Padding
        let constraint: PDF.Context.Constraint
        let layoutBoxLLX: PDF.UserSpace.X
        let layoutBoxURX: PDF.UserSpace.X
        let forcePageBreakAfter: Bool
        let avoidPageBreakAfter: Bool
        let avoidPageBreakInside: Bool

        init(from context: PDF.HTML.Context) {
            self.style = context.pdf.style
            self.margin = context.pdf.margin
            self.padding = context.pdf.padding
            self.constraint = context.pdf.constraint
            self.layoutBoxLLX = context.pdf.layout.box.llx
            self.layoutBoxURX = context.pdf.layout.box.urx
            self.forcePageBreakAfter = context.forcePageBreakAfter
            self.avoidPageBreakAfter = context.avoidPageBreakAfter
            self.avoidPageBreakInside = context.avoidPageBreakInside
        }
    }
}

extension PDF.HTML.Context.Style.Snapshot {
    func restore(to context: inout PDF.HTML.Context) {
        context.pdf.style = style
        context.pdf.margin = margin
        context.pdf.padding = padding
        context.pdf.constraint = constraint
        // Y position advances through content — only restore X bounds
        context.pdf.layout.box.llx = layoutBoxLLX
        context.pdf.layout.box.urx = layoutBoxURX
    }
}
