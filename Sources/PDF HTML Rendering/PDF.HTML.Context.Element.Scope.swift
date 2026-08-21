import PDF_Rendering
import W3C_CSS_Values

extension PDF.HTML.Context.Element {

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

        let savedTable: PDF.HTML.Context.Table?

        let savedPendingMargin: PDF.UserSpace.Height

        let isVoid: Bool

        var pendingBorderTop: PendingSideBorder? = nil
        var pendingBorderRight: PendingSideBorder? = nil
        var pendingBorderBottom: PendingSideBorder? = nil
        var pendingBorderLeft: PendingSideBorder? = nil
    }
}

extension PDF.HTML.Context.Element.Scope {

    public struct PendingSideBorder: Sendable {
        public let width: PDF.UserSpace.Size<1>
        public let style: W3C_CSS_Values.LineStyle
        public let color: PDF.Color
    }
}
