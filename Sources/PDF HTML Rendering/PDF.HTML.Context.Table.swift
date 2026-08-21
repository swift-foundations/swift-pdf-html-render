import Dictionary_Primitives
import HTML_Rendering_Core
import Layout_Primitives
import PDF_Rendering
import Render_Primitives

extension PDF.HTML.Context {

    public struct Table {

        public var bounds: PDF.UserSpace.Rectangle

        public var columnWidths: [PDF.UserSpace.Width] {
            didSet {

                _recomputeCumulativeColumnWidths()
            }
        }

        public var rowHeights: [PDF.UserSpace.Height] {
            didSet {

                _recomputeCumulativeRowHeights()
            }
        }

        private var _cumulativeColumnWidths: [PDF.UserSpace.Width] = [.zero]

        private var _cumulativeRowHeights: [PDF.UserSpace.Height] = [.zero]

        public var spans: Grid = .init()

        public var currentRow: Int = 0

        public var currentColumn: Int = 0

        internal var _cellPadding: PDF.UserSpace.Size<1>

        public var borderColor: PDF.Color

        public var borderWidth: PDF.UserSpace.Size<1>

        public var headerBackground: PDF.Color?

        public var alternatingRowColor: PDF.Color?

        public var totalRowsRendered: Int = 0

        public var columnsInitialized: Bool = false

        public var hasExplicitWidth: Bool = false

        var recording: Recording?

        public var maxCellHeightInCurrentRow: PDF.UserSpace.Height = PDF.UserSpace.Height(0)

        public var pendingCellBorders: [PendingCellBorder] = []

        public var deferredSpanningCells: [Deferred] = []

        public var header: Header = .init()

        public var tableStartY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        public var tableEndY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        public var horizontalLineSkips: [Int: [(start: Int, end: Int)]] = [:]

        public var verticalLineSkips: [Int: [(start: Int, end: Int)]] = [:]

        public var currentRowMaxAscent: PDF.UserSpace.Height = .init(0)

        public var currentRowMaxDescent: PDF.UserSpace.Height = .init(0)

        public var currentFragmentStartY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        public var currentFragmentEndY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        public init(
            bounds: PDF.UserSpace.Rectangle,
            columnWidths: [PDF.UserSpace.Width],
            rowHeights: [PDF.UserSpace.Height],
            cellPadding: PDF.UserSpace.Size<1> = 4,
            borderColor: PDF.Color = .gray(0.3),
            borderWidth: PDF.UserSpace.Size<1> = 0.5,
            headerBackground: PDF.Color? = .gray(0.9),
            alternatingRowColor: PDF.Color? = nil
        ) {
            self.bounds = bounds
            self.columnWidths = columnWidths
            self.rowHeights = rowHeights
            self._cellPadding = cellPadding
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.headerBackground = headerBackground
            self.alternatingRowColor = alternatingRowColor

            _recomputeCumulativeColumnWidths()
            _recomputeCumulativeRowHeights()
        }
    }
}

extension PDF.HTML.Context.Table {

    private mutating func _recomputeCumulativeColumnWidths() {
        var cumulative: [PDF.UserSpace.Width] = [.zero]
        cumulative.reserveCapacity(columnWidths.count + 1)
        var sum: PDF.UserSpace.Width = .zero
        for width in columnWidths {
            sum += width
            cumulative.append(sum)
        }
        _cumulativeColumnWidths = cumulative
    }

    private mutating func _recomputeCumulativeRowHeights() {
        var cumulative: [PDF.UserSpace.Height] = [.zero]
        cumulative.reserveCapacity(rowHeights.count + 1)
        var sum: PDF.UserSpace.Height = .zero
        for height in rowHeights {
            sum += height
            cumulative.append(sum)
        }
        _cumulativeRowHeights = cumulative
    }

    public var columnCount: Int { columnWidths.count }

    public var rowCount: Int { rowHeights.count }

    public func xForColumn(_ column: Int) -> PDF.UserSpace.X {
        let offset = widthForColumns(0, count: column)
        return bounds.llx + offset
    }

    public func yForRow(_ row: Int) -> PDF.UserSpace.Y {
        let offset = heightForRows(0, count: row)
        return bounds.lly + offset
    }

    public func widthForColumns(_ startColumn: Int, count: Int) -> PDF.UserSpace.Width {
        let endColumn = min(startColumn + count, columnWidths.count)
        guard endColumn > startColumn else { return .zero }

        return _cumulativeColumnWidths[endColumn] - _cumulativeColumnWidths[startColumn]
    }

    public func heightForRows(_ startRow: Int, count: Int) -> PDF.UserSpace.Height {
        let endRow = min(startRow + count, rowHeights.count)
        guard endRow > startRow else { return .zero }

        return _cumulativeRowHeights[endRow] - _cumulativeRowHeights[startRow]
    }

    public var cell: Cell {
        Cell(table: self, row: nil, column: nil, colspan: 1, rowspan: 1)
    }

    public mutating func advanceToNextAvailableColumn() {
        while currentColumn < columnCount
            && spans.isOccupied(row: totalRowsRendered, column: currentColumn)
        {
            currentColumn += 1
        }
    }
}
