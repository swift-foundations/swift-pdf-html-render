import Layout_Primitives

extension PDF.HTML.Context.Table {

    public struct PendingCellBorder {
        let column: Int
        let colspan: Int
        let rowspan: Int
        let isHeader: Bool
        let textAlignment: Horizontal.Alignment

        let pendingBorderTop: PDF.HTML.Context.Element.Scope.PendingSideBorder?
        let pendingBorderRight: PDF.HTML.Context.Element.Scope.PendingSideBorder?
        let pendingBorderBottom: PDF.HTML.Context.Element.Scope.PendingSideBorder?
        let pendingBorderLeft: PDF.HTML.Context.Element.Scope.PendingSideBorder?

        init(
            column: Int,
            colspan: Int,
            rowspan: Int,
            isHeader: Bool,
            textAlignment: Horizontal.Alignment,
            pendingBorderTop: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil,
            pendingBorderRight: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil,
            pendingBorderBottom: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil,
            pendingBorderLeft: PDF.HTML.Context.Element.Scope.PendingSideBorder? = nil
        ) {
            self.column = column
            self.colspan = colspan
            self.rowspan = rowspan
            self.isHeader = isHeader
            self.textAlignment = textAlignment
            self.pendingBorderTop = pendingBorderTop
            self.pendingBorderRight = pendingBorderRight
            self.pendingBorderBottom = pendingBorderBottom
            self.pendingBorderLeft = pendingBorderLeft
        }
    }
}
