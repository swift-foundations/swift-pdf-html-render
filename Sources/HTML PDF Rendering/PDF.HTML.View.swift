// PDF.HTML.View.swift
// Static dispatch PDF rendering for HTML.View types

import HTML_Renderable
import OrderedCollections
import PDF_Rendering
import Rendering

// MARK: - Context combining PDF.Context and Configuration

extension PDF.HTML {
    /// Combined context for HTML to PDF rendering.
    ///
    /// This product type bundles `PDF.Context` (mutable layout state) with
    /// `PDF.HTML.Configuration` (immutable rendering settings), providing
    /// a single context parameter for the render method.
    public struct Context {
        /// The mutable PDF layout context (position, font, page state, etc.)
        public var pdf: PDF.Context

        /// The immutable rendering configuration
        public let configuration: PDF.HTML.Configuration

        /// Active table layout context (nil when not in a table)
        public var tableContext: Context.Table?

        /// HTML attributes for the current element (colspan, rowspan, etc.)
        ///
        /// Populated by `HTML._Attributes` wrapper during rendering.
        /// Used by table cell rendering to extract colspan/rowspan values.
        public var attributes: OrderedDictionary<String, String> = [:]

        /// Pending bottom margin from previous block element (for margin collapsing).
        ///
        /// In CSS, adjacent vertical margins collapse - only the larger margin is used.
        /// This tracks the bottom margin of the previous block element so it can be
        /// collapsed with the top margin of the next block element.
        public var pendingBottomMargin: PDF.UserSpace.Unit = 0

        /// Deferred render closure for keep-with-next behavior (page-break-after: avoid).
        ///
        /// When an element with `page-break-after: avoid` is encountered, instead of
        /// rendering immediately, we store a closure that will render the element.
        /// When the next block element is rendered, we check if the deferred header
        /// plus at least one line of content fits on the current page. If not, we
        /// start a new page before rendering the deferred content.
        public var deferredKeepWithNextRender: DeferredRender?

        /// Deferred render operation for sticky headers
        public struct DeferredRender: @unchecked Sendable {
            /// Closure that renders the deferred content
            ///
            /// Note: Not marked @Sendable because rendering is single-threaded and synchronous.
            /// The closure captures generic view types that aren't Sendable.
            public let render: (inout PDF.HTML.Context) -> Void
            /// Measured height of the deferred content
            public let measuredHeight: PDF.UserSpace.Height
        }

        /// Snapshot of PDF context state for restoration during deferred rendering
        ///
        /// **Important**: Only captures and restores **style** (font, color, etc.),
        /// NOT the layout position. The deferred content should render at the
        /// current Y position when the closure executes, not where the header
        /// was originally encountered.
        public struct PDFContextSnapshot: Sendable {
            public let style: PDF.Context.Style.Resolved

            public init(from context: PDF.Context) {
                self.style = context.style
            }

            public func restore(to context: inout PDF.Context) {
                context.style = style
                // NOTE: Do NOT restore layoutBox - the deferred content should
                // render at the current position, not the original position
            }
        }

        /// Flag indicating the current element should avoid page break after it.
        /// Set by `page-break-after: avoid` CSS property.
        public var avoidPageBreakAfter: Bool = false

        public init(pdf: PDF.Context, configuration: PDF.HTML.Configuration) {
            self.pdf = pdf
            self.configuration = configuration
            self.tableContext = nil
            self.pendingBottomMargin = 0
            self.deferredKeepWithNextRender = nil
            self.avoidPageBreakAfter = false
        }

        /// Apply collapsed margin between blocks.
        ///
        /// CSS margin collapsing: adjacent vertical margins collapse to the larger value.
        /// This method flushes any pending inline content, applies the effective margin
        /// (max of pending bottom and new top), then stores the new bottom margin.
        ///
        /// - Parameters:
        ///   - topMargin: Top margin of the current element
        ///   - bottomMargin: Bottom margin of the current element (stored for next collapse)
        public mutating func applyCollapsedMargin(
            top topMargin: PDF.UserSpace.Unit,
            bottom bottomMargin: PDF.UserSpace.Unit
        ) {
            // Flush pending inline content
            if pdf.hasInlineRuns {
                pdf.flushInlineRuns()
            }

            // CSS margin collapse: use larger of adjacent margins
            let collapsedMargin = max(pendingBottomMargin, topMargin)

            // Apply the collapsed margin
            if collapsedMargin > 0 {
                pdf.advance(PDF.UserSpace.Y(collapsedMargin))
            }

            // Store bottom margin for next collapse
            pendingBottomMargin = bottomMargin
        }

        /// Reset margin collapsing state.
        ///
        /// Call this when starting a new formatting context (e.g., new page,
        /// entering a block formatting context like a table cell).
        public mutating func resetMarginCollapsing() {
            pendingBottomMargin = 0
        }
    }
}

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

        /// Grid tracking cells occupied by rowspan.
        /// `spanGrid[row][column]` is non-nil if that cell is occupied by a spanning cell.
        public var spanGrid: [[CellSpan?]]

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

        // MARK: - Current Position

        /// Current row index during rendering (0-based)
        public var currentRow: Int = 0

        /// Current column index during rendering (0-based)
        public var currentColumn: Int = 0

        // MARK: - Styling

        /// Cell padding (applied uniformly)
        public var cellPadding: PDF.UserSpace.Unit

        /// Border color for cell edges
        public var borderColor: PDF.Color

        /// Border width for cell edges
        public var borderWidth: PDF.UserSpace.Unit

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

        /// Deferred spanning cells (rowspan > 1) that need borders drawn after all rows
        public struct DeferredSpanningCell {
            let originRow: Int
            let column: Int
            let colspan: Int
            let rowspan: Int
            let isHeader: Bool
            let startY: PDF.UserSpace.Y
        }
        public var deferredSpanningCells: [DeferredSpanningCell] = []

        // MARK: - Repeating Headers on Page Break

        /// Stored header cell content for repetition on page breaks
        public struct HeaderCell {
            public let text: String
            public let colspan: Int

            public init(text: String, colspan: Int = 1) {
                self.text = text
                self.colspan = colspan
            }
        }

        /// Header cells captured during thead rendering (nil if no header)
        public var headerCells: [HeaderCell]?

        /// Whether we're currently inside a thead section (for capturing header content)
        public var isCapturingHeader: Bool = false

        /// Temporary storage for header cells being captured
        public var pendingHeaderCells: [HeaderCell] = []

        /// Height of the header row (for page break calculations)
        public var headerRowHeight: PDF.UserSpace.Height = PDF.UserSpace.Height(0)

        // MARK: - Initialization

        public init(
            bounds: PDF.UserSpace.Rectangle,
            columnWidths: [PDF.UserSpace.Width],
            rowHeights: [PDF.UserSpace.Height],
            spanGrid: [[CellSpan?]] = [],
            cellPadding: PDF.UserSpace.Unit = 4,
            borderColor: PDF.Color = .gray(0.3),
            borderWidth: PDF.UserSpace.Unit = 0.5,
            headerBackground: PDF.Color? = .gray(0.9),
            alternatingRowColor: PDF.Color? = nil
        ) {
            self.bounds = bounds
            self.columnWidths = columnWidths
            self.rowHeights = rowHeights
            self.spanGrid = spanGrid
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
            var x = bounds.llx.value
            for i in 0..<min(column, columnWidths.count) {
                x += columnWidths[i].value
            }
            return PDF.UserSpace.X(x)
        }

        /// Get Y position for a given row
        public func yForRow(_ row: Int) -> PDF.UserSpace.Y {
            var y = bounds.lly.value
            for i in 0..<min(row, rowHeights.count) {
                y += rowHeights[i].value
            }
            return PDF.UserSpace.Y(y)
        }

        /// Calculate total width for a range of columns (for colspan)
        public func widthForColumns(_ startColumn: Int, count: Int) -> PDF.UserSpace.Width {
            let endColumn = min(startColumn + count, columnWidths.count)
            guard endColumn > startColumn else { return PDF.UserSpace.Width(0) }
            var total: PDF.UserSpace.Unit = 0
            for i in startColumn..<endColumn {
                total += columnWidths[i].value
            }
            return PDF.UserSpace.Width(total)
        }

        /// Calculate total height for a range of rows (for rowspan)
        public func heightForRows(_ startRow: Int, count: Int) -> PDF.UserSpace.Height {
            let endRow = min(startRow + count, rowHeights.count)
            guard endRow > startRow else { return PDF.UserSpace.Height(0) }
            var total: PDF.UserSpace.Unit = 0
            for i in startRow..<endRow {
                total += rowHeights[i].value
            }
            return PDF.UserSpace.Height(total)
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
            let cell = cellBounds(row: row, column: column, colspan: colspan, rowspan: rowspan)
            return PDF.UserSpace.Rectangle(
                x: PDF.UserSpace.X(cell.llx.value + cellPadding),
                y: PDF.UserSpace.Y(cell.lly.value + cellPadding),
                width: PDF.UserSpace.Width(cell.width.value - cellPadding * 2),
                height: PDF.UserSpace.Height(cell.height.value - cellPadding * 2)
            )
        }

        /// Check if a cell position is occupied by a rowspan from a previous row
        public func isOccupied(row: Int, column: Int) -> Bool {
            guard row < spanGrid.count, column < (spanGrid[row].count) else { return false }
            return spanGrid[row][column] != nil
        }

        /// Find the next available column in the current row (skipping spanned cells)
        ///
        /// Uses `totalRowsRendered` as the row index since that tracks the actual
        /// row number across the entire table (currentRow is reset per row rendering).
        public mutating func advanceToNextAvailableColumn() {
            while currentColumn < columnCount && isOccupied(row: totalRowsRendered, column: currentColumn) {
                currentColumn += 1
            }
        }

        /// Mark cells as occupied by a rowspan/colspan cell
        ///
        /// Called when a cell has rowspan > 1 to mark subsequent rows' cells as occupied.
        /// The spanGrid is extended dynamically if needed.
        public mutating func markSpannedCells(
            fromRow originRow: Int,
            column originColumn: Int,
            rowspan: Int,
            colspan: Int
        ) {
            let span = CellSpan(
                originRow: originRow,
                originColumn: originColumn,
                rowSpan: rowspan,
                colSpan: colspan
            )

            // Ensure spanGrid has enough rows
            while spanGrid.count <= originRow + rowspan - 1 {
                spanGrid.append(Array(repeating: nil, count: columnCount))
            }

            // Mark all cells covered by this span (except the origin cell itself)
            for r in originRow..<(originRow + rowspan) {
                // Ensure this row has enough columns
                while spanGrid[r].count < columnCount {
                    spanGrid[r].append(nil)
                }

                for c in originColumn..<(originColumn + colspan) {
                    // Skip the origin cell (row 0, col 0 of the span)
                    if r == originRow && c == originColumn {
                        continue
                    }
                    if c < spanGrid[r].count {
                        spanGrid[r][c] = span
                    }
                }
            }
        }
    }
}

// MARK: - PDF.HTML.View Protocol

extension PDF.HTML {
    /// Protocol for types that can be rendered to PDF content.
    ///
    /// This protocol enables static dispatch for HTML to PDF rendering,
    /// following the same pattern as `PDF.View` which renders directly to context.
    ///
    /// Note: This protocol does NOT extend `Renderable` because HTML types
    /// already conform to `Renderable` via `HTML.View` with different associated
    /// types (`Context == HTML.Context`, `Output == UInt8`). Having two different
    /// `Renderable` conformances would cause a conflict.
    public protocol View {
        /// Render this view to PDF content.
        ///
        /// - Parameters:
        ///   - view: The view to render
        ///   - context: Combined context with PDF layout state and configuration
        static func _render(
            _ view: Self,
            context: inout PDF.HTML.Context
        )
    }
}

// MARK: - Default Implementation for HTML.View types

extension PDF.HTML.View where Self: HTML.View, Self.Content: PDF.HTML.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        Self.Content._render(view.body, context: &context)
    }
}
