import PDF_Rendering

extension PDF.HTML.Context.Table {

    public struct Cell {
        private let table: PDF.HTML.Context.Table
        private let row: Int?
        private let column: Int?
        private let colspan: Int
        private let rowspan: Int

        internal init(
            table: PDF.HTML.Context.Table,
            row: Int?,
            column: Int?,
            colspan: Int,
            rowspan: Int
        ) {
            self.table = table
            self.row = row
            self.column = column
            self.colspan = colspan
            self.rowspan = rowspan
        }
    }
}

extension PDF.HTML.Context.Table.Cell {

    public var padding: PDF.UserSpace.Size<1> {
        table._cellPadding
    }

    public func callAsFunction(
        row: Int,
        column: Int,
        colspan: Int = 1,
        rowspan: Int = 1
    ) -> Self {
        Self(table: table, row: row, column: column, colspan: colspan, rowspan: rowspan)
    }

    public var bounds: PDF.UserSpace.Rectangle {
        guard let row, let column else {
            preconditionFailure(
                "Cell must be positioned with cell(row:column:) to access bounds"
            )
        }
        let x = table.xForColumn(column)
        let y = table.yForRow(row)
        let width = table.widthForColumns(column, count: colspan)
        let height = table.heightForRows(row, count: rowspan)
        return PDF.UserSpace.Rectangle(x: x, y: y, width: width, height: height)
    }

    public var content: PDF.UserSpace.Rectangle {
        bounds.insetBy(dx: table._cellPadding.width, dy: table._cellPadding.height)
    }
}
