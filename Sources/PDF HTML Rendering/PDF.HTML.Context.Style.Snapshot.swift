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
        let marginTop: PDF.UserSpace.Height?
        let marginRight: PDF.UserSpace.Width?
        let marginBottom: PDF.UserSpace.Height?
        let marginLeft: PDF.UserSpace.Width?
        let paddingTop: PDF.UserSpace.Height?
        let paddingRight: PDF.UserSpace.Width?
        let paddingBottom: PDF.UserSpace.Height?
        let paddingLeft: PDF.UserSpace.Width?
        let explicitWidth: PDF.UserSpace.Width?
        let explicitHeight: PDF.UserSpace.Height?
        let layoutBoxLLX: PDF.UserSpace.X
        let layoutBoxURX: PDF.UserSpace.X

        init(from context: PDF.HTML.Context) {
            self.style = context.pdf.style
            self.marginTop = context.pdf.marginTop
            self.marginRight = context.pdf.marginRight
            self.marginBottom = context.pdf.marginBottom
            self.marginLeft = context.pdf.marginLeft
            self.paddingTop = context.pdf.paddingTop
            self.paddingRight = context.pdf.paddingRight
            self.paddingBottom = context.pdf.paddingBottom
            self.paddingLeft = context.pdf.paddingLeft
            self.explicitWidth = context.pdf.explicitWidth
            self.explicitHeight = context.pdf.explicitHeight
            self.layoutBoxLLX = context.pdf.layoutBox.llx
            self.layoutBoxURX = context.pdf.layoutBox.urx
        }

        func restore(to context: inout PDF.HTML.Context) {
            context.pdf.style = style
            context.pdf.marginTop = marginTop
            context.pdf.marginRight = marginRight
            context.pdf.marginBottom = marginBottom
            context.pdf.marginLeft = marginLeft
            context.pdf.paddingTop = paddingTop
            context.pdf.paddingRight = paddingRight
            context.pdf.paddingBottom = paddingBottom
            context.pdf.paddingLeft = paddingLeft
            context.pdf.explicitWidth = explicitWidth
            context.pdf.explicitHeight = explicitHeight
            // Y position advances through content — only restore X bounds
            context.pdf.layoutBox.llx = layoutBoxLLX
            context.pdf.layoutBox.urx = layoutBoxURX
        }
    }
}
