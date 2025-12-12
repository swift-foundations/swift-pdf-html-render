//
//  File.swift
//  swift-pdf-html-rendering
//
//  Created by Coen ten Thije Boonkkamp on 10/12/2025.
//

import HTML_Renderable
import Layout
import OrderedCollections
import PDF_Rendering
import Rendering

// MARK: - Table Layout Support

extension PDF.HTML.Context {
    /// Context for table layout with auto-sized columns and span support.
    ///
    /// Uses Geometry types from swift-standards for type-safe dimensions:
    /// - `PDF.UserSpace.Rectangle` for table/cell bounds
    /// - `PDF.UserSpace.Width`/`Height` for column/row dimensions
    /// - `PDF.UserSpace.EdgeInsets` for cell padding
    public struct Table {
        // MARK: - Layout Bounds

        /// Table bounds using Geometry.Rectangle (ll/ur corners)
        public var bounds: PDF.UserSpace.Rectangle

        /// Column widths (auto-sized from content)
        public var columnWidths: [PDF.UserSpace.Width]

        /// Row heights (auto-sized from content, considering rowspan)
        public var rowHeights: [PDF.UserSpace.Height]

        // MARK: - Span Tracking

        /// Grid tracking cells occupied by rowspan/colspan
        public var spans: SpanGrid = .init()

        /// Tracks which cells are occupied by rowspan/colspan from other cells
        public struct SpanGrid: Sendable {
            /// `grid[row][column]` is non-nil if that cell is occupied by a spanning cell
            private var grid: [[CellSpan?]] = []

            /// Information about a cell span occupying grid positions
            public struct CellSpan: Sendable {
                /// Row where the spanning cell originates
                public let originRow: Int
                /// Column where the spanning cell originates
                public let originColumn: Int
                /// Number of rows the cell spans
                public let rowSpan: Int
                /// Number of columns the cell spans
                public let colSpan: Int

                public init(originRow: Int, originColumn: Int, rowSpan: Int, colSpan: Int) {
                    self.originRow = originRow
                    self.originColumn = originColumn
                    self.rowSpan = rowSpan
                    self.colSpan = colSpan
                }
            }

            /// Check if a cell position is occupied by a span from another cell
            public func isOccupied(row: Int, column: Int) -> Bool {
                guard row < grid.count, column < grid[row].count else { return false }
                return grid[row][column] != nil
            }

            /// Mark cells as occupied by a rowspan/colspan cell
            public mutating func mark(
                fromRow originRow: Int,
                column originColumn: Int,
                rowspan: Int,
                colspan: Int,
                columnCount: Int
            ) {
                let span = CellSpan(
                    originRow: originRow,
                    originColumn: originColumn,
                    rowSpan: rowspan,
                    colSpan: colspan
                )

                // Ensure grid has enough rows
                while grid.count <= originRow + rowspan - 1 {
                    grid.append(Array(repeating: nil, count: columnCount))
                }

                // Mark all cells covered by this span (except the origin cell itself)
                for r in originRow..<(originRow + rowspan) {
                    // Ensure this row has enough columns
                    while grid[r].count < columnCount {
                        grid[r].append(nil)
                    }

                    for c in originColumn..<(originColumn + colspan) {
                        // Skip the origin cell
                        if r == originRow && c == originColumn { continue }
                        if c < grid[r].count {
                            grid[r][c] = span
                        }
                    }
                }
            }
        }

        // MARK: - Current Position

        /// Current row index during rendering (0-based)
        public var currentRow: Int = 0

        /// Current column index during rendering (0-based)
        public var currentColumn: Int = 0

        // MARK: - Styling

        /// Cell padding (applied uniformly)
        public var cellPadding: PDF.UserSpace.Size<1>

        /// Border color for cell edges
        public var borderColor: PDF.Color

        /// Border width for cell edges
        public var borderWidth: PDF.UserSpace.Size<1>

        /// Background color for header cells (nil for transparent)
        public var headerBackground: PDF.Color?

        /// Alternating row background color (nil for no alternation)
        public var alternatingRowColor: PDF.Color?

        /// Track total rows rendered for proper Y advancement
        public var totalRowsRendered: Int = 0

        /// Whether columns have been initialized (from first row)
        public var columnsInitialized: Bool = false

        /// Measurement mode - count columns without drawing
        public var measureOnly: Bool = false

        /// Track the maximum cell height in the current row (for multi-line content)
        public var maxCellHeightInCurrentRow: PDF.UserSpace.Height = PDF.UserSpace.Height(0)

        /// Pending cell borders to draw after content (so we know actual row height)
        public struct PendingCellBorder {
            let column: Int
            let colspan: Int
            let rowspan: Int
            let isHeader: Bool
            let textAlignment: Horizontal.Alignment
        }
        public var pendingCellBorders: [PendingCellBorder] = []

        /// Deferred spanning cells (rowspan > 1) that need content + borders drawn after all rows
        public struct DeferredSpanningCell {
            let originRow: Int
            let column: Int
            let colspan: Int
            let rowspan: Int
            let isHeader: Bool
            let startY: PDF.UserSpace.Y
            // Content rendering data for vertical centering
            let contentWidth: PDF.UserSpace.Width
            let contentX: PDF.UserSpace.X
            let savedStyle: PDF.Context.Style.Resolved
            let contentText: String
            let textAlignment: Horizontal.Alignment
        }
        public var deferredSpanningCells: [DeferredSpanningCell] = []

        // MARK: - Repeating Headers on Page Break

        /// State for capturing and repeating table headers on page breaks
        public var header: HeaderState = .init()

        /// Manages header capture and repetition for multi-page tables
        public struct HeaderState: Sendable {
            /// A captured header cell for repetition
            public struct Cell: Sendable {
                public let text: String
                public let colspan: Int

                public init(text: String, colspan: Int = 1) {
                    self.text = text
                    self.colspan = colspan
                }
            }

            /// Captured header cells (nil if no header in table)
            public var cells: [Cell]?

            /// Whether we're currently inside a thead section (capturing content)
            public var isCapturing: Bool = false

            /// Temporary storage for cells being captured during thead rendering
            public var pendingCells: [Cell] = []

            /// Height of the header row (for page break calculations)
            public var rowHeight: PDF.UserSpace.Height = .zero

            /// Returns true if there are captured header cells to repeat
            public var hasHeader: Bool { cells != nil && !(cells?.isEmpty ?? true) }

            /// Finalize capturing - move pending cells to captured cells
            public mutating func finalizeCapture() {
                if !pendingCells.isEmpty {
                    cells = pendingCells
                    pendingCells = []
                }
                isCapturing = false
            }

            /// Start capturing header cells
            public mutating func startCapturing() {
                isCapturing = true
                pendingCells = []
            }

            /// Add a cell during capture
            public mutating func addCell(_ cell: Cell) {
                if isCapturing {
                    pendingCells.append(cell)
                }
            }
        }

        /// Starting Y position of the table (for grid border drawing)
        public var tableStartY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        /// Ending Y position of the table (updated as rows complete)
        public var tableEndY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        /// Tracks which horizontal lines should be skipped due to rowspan
        /// Key: row index (line between row i-1 and row i), Value: column ranges to skip
        public var horizontalLineSkips: [Int: [(start: Int, end: Int)]] = [:]

        /// Tracks which vertical lines should be skipped due to colspan
        /// Key: column index (line between col j-1 and col j), Value: row ranges to skip
        public var verticalLineSkips: [Int: [(start: Int, end: Int)]] = [:]

        // MARK: - Row Baseline Alignment

        /// Max font ascent across all cells in current row (for baseline alignment)
        public var currentRowMaxAscent: PDF.UserSpace.Height = 0

        /// Max font descent across all cells in current row (absolute value, for baseline alignment)
        public var currentRowMaxDescent: PDF.UserSpace.Height = 0

        // MARK: - Multi-Page Fragment Tracking

        /// Starting Y position of the current page fragment (for per-fragment border drawing)
        /// This is reset after each page break to track borders independently per page.
        public var currentFragmentStartY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        /// Ending Y position of the current page fragment (updated as rows complete)
        public var currentFragmentEndY: PDF.UserSpace.Y = PDF.UserSpace.Y(0)

        // MARK: - Initialization

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
            self.cellPadding = cellPadding
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.headerBackground = headerBackground
            self.alternatingRowColor = alternatingRowColor
        }

        // MARK: - Column Access

        /// Number of columns in the table
        public var columnCount: Int { columnWidths.count }

        /// Number of rows in the table
        public var rowCount: Int { rowHeights.count }

        /// Get X position for a given column
        public func xForColumn(_ column: Int) -> PDF.UserSpace.X {
            let offset = widthForColumns(0, count: column)
            return PDF.UserSpace.X(bounds.llx.value + offset.value)
        }

        /// Get Y position for a given row
        public func yForRow(_ row: Int) -> PDF.UserSpace.Y {
            let offset = heightForRows(0, count: row)
            return PDF.UserSpace.Y(bounds.lly.value + offset.value)
        }

        /// Calculate total width for a range of columns (for colspan)
        public func widthForColumns(_ startColumn: Int, count: Int) -> PDF.UserSpace.Width {
            let endColumn = min(startColumn + count, columnWidths.count)
            guard endColumn > startColumn else { return .zero }
            return columnWidths[startColumn..<endColumn].reduce(.zero, +)
        }

        /// Calculate total height for a range of rows (for rowspan)
        public func heightForRows(_ startRow: Int, count: Int) -> PDF.UserSpace.Height {
            let endRow = min(startRow + count, rowHeights.count)
            guard endRow > startRow else { return .zero }
            return rowHeights[startRow..<endRow].reduce(.zero, +)
        }

        /// Get cell bounds for given row/column with optional spanning
        public func cellBounds(
            row: Int,
            column: Int,
            colspan: Int = 1,
            rowspan: Int = 1
        ) -> PDF.UserSpace.Rectangle {
            let x = xForColumn(column)
            let y = yForRow(row)
            let width = widthForColumns(column, count: colspan)
            let height = heightForRows(row, count: rowspan)
            return PDF.UserSpace.Rectangle(x: x, y: y, width: width, height: height)
        }

        /// Get content bounds (cell bounds minus padding)
        public func contentBounds(
            row: Int,
            column: Int,
            colspan: Int = 1,
            rowspan: Int = 1
        ) -> PDF.UserSpace.Rectangle {
            cellBounds(row: row, column: column, colspan: colspan, rowspan: rowspan)
                .insetBy(dx: cellPadding.width, dy: cellPadding.height)
        }

        /// Find the next available column in the current row (skipping spanned cells)
        ///
        /// Uses `totalRowsRendered` as the row index since that tracks the actual
        /// row number across the entire table (currentRow is reset per row rendering).
        public mutating func advanceToNextAvailableColumn() {
            while currentColumn < columnCount && spans.isOccupied(row: totalRowsRendered, column: currentColumn) {
                currentColumn += 1
            }
        }
    }
}
