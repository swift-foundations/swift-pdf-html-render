// PDF.HTML.TableMeasurement.swift
// Two-pass table measurement system for auto-sizing columns.

import HTML_Renderable
import PDF_Rendering

// MARK: - Table Measurement

extension PDF.HTML {
    /// Collected table structure during measurement pass.
    ///
    /// This structure captures the table layout during a measurement pass,
    /// allowing column widths and row heights to be calculated before rendering.
    public struct TableMeasurement {
        /// Table sections (head, body, foot)
        public var sections: [Section] = []

        /// Total number of columns (determined from max cells in any row)
        public var columnCount: Int = 0

        // MARK: - Section

        /// A table section (thead, tbody, tfoot)
        public struct Section {
            public var type: SectionType
            public var rows: [Row]

            public init(type: SectionType, rows: [Row] = []) {
                self.type = type
                self.rows = rows
            }
        }

        /// Section type
        public enum SectionType: Sendable {
            case head
            case body
            case foot
        }

        // MARK: - Row

        /// A table row
        public struct Row {
            public var cells: [Cell]

            public init(cells: [Cell] = []) {
                self.cells = cells
            }

            /// Calculate the effective column count (accounting for colspan)
            public var effectiveColumnCount: Int {
                cells.reduce(0) { $0 + $1.colspan }
            }
        }

        // MARK: - Cell

        /// A table cell with measured dimensions
        public struct Cell {
            /// Number of columns this cell spans
            public var colspan: Int

            /// Number of rows this cell spans
            public var rowspan: Int

            /// Whether this is a header cell (th vs td)
            public var isHeader: Bool

            /// Measured content width (natural width without constraints)
            public var measuredWidth: PDF.UserSpace.Width

            /// Measured content height (natural height without constraints)
            public var measuredHeight: PDF.UserSpace.Height

            /// Deferred render closure for the cell content
            public var renderContent: (@Sendable (inout PDF.HTML.Context) -> Void)?

            public init(
                colspan: Int = 1,
                rowspan: Int = 1,
                isHeader: Bool = false,
                measuredWidth: PDF.UserSpace.Width = 0,
                measuredHeight: PDF.UserSpace.Height = 0,
                renderContent: (@Sendable (inout PDF.HTML.Context) -> Void)? = nil
            ) {
                self.colspan = colspan
                self.rowspan = rowspan
                self.isHeader = isHeader
                self.measuredWidth = measuredWidth
                self.measuredHeight = measuredHeight
                self.renderContent = renderContent
            }
        }

        // MARK: - Initialization

        public init() {}

        // MARK: - Building

        /// Add a section to the measurement
        public mutating func addSection(_ section: Section) {
            sections.append(section)
            updateColumnCount(from: section)
        }

        /// Update column count from a section
        private mutating func updateColumnCount(from section: Section) {
            for row in section.rows {
                let rowColumnCount = row.effectiveColumnCount
                if rowColumnCount > columnCount {
                    columnCount = rowColumnCount
                }
            }
        }

        // MARK: - Column Width Calculation

        /// Calculate optimal column widths from measured content.
        ///
        /// Algorithm:
        /// 1. Determine column count from max cells (accounting for colspan)
        /// 2. Initialize with minimum widths (padding × 2)
        /// 3. Process single-span cells: track max width per column
        /// 4. Process multi-span cells: distribute excess width proportionally
        /// 5. Scale down if total exceeds available width
        public func calculateColumnWidths(
            availableWidth: PDF.UserSpace.Width,
            cellPadding: PDF.UserSpace.Unit
        ) -> [PDF.UserSpace.Width] {
            guard columnCount > 0 else { return [] }

            // Initialize with minimum widths (padding on each side)
            let minWidth = cellPadding * 2
            var columnWidths = Array(repeating: PDF.UserSpace.Width(minWidth), count: columnCount)

            // Pass 1: Process single-span cells
            for section in sections {
                for row in section.rows {
                    var col = 0
                    for cell in row.cells {
                        if cell.colspan == 1 && col < columnCount {
                            // Single-column cell - update max width for this column
                            let contentWidth = cell.measuredWidth.value + cellPadding * 2
                            if contentWidth > columnWidths[col].value {
                                columnWidths[col] = PDF.UserSpace.Width(contentWidth)
                            }
                        }
                        col += cell.colspan
                    }
                }
            }

            // Pass 2: Process multi-span cells
            for section in sections {
                for row in section.rows {
                    var col = 0
                    for cell in row.cells {
                        if cell.colspan > 1 {
                            let endCol = min(col + cell.colspan, columnCount)
                            let spannedCols = col..<endCol

                            // Calculate current total width of spanned columns
                            let currentTotal = spannedCols.reduce(PDF.UserSpace.Unit(0)) {
                                $0 + columnWidths[$1].value
                            }

                            // Required width including padding
                            let requiredWidth = cell.measuredWidth.value + cellPadding * 2

                            // If cell needs more width, distribute excess proportionally
                            if requiredWidth > currentTotal {
                                let excess = requiredWidth - currentTotal
                                let perColumn = excess / PDF.UserSpace.Unit(cell.colspan)
                                for c in spannedCols {
                                    columnWidths[c] = PDF.UserSpace.Width(columnWidths[c].value + perColumn)
                                }
                            }
                        }
                        col += cell.colspan
                    }
                }
            }

            // Pass 3: Scale down if total exceeds available width
            let totalWidth = columnWidths.reduce(PDF.UserSpace.Unit(0)) { $0 + $1.value }
            if totalWidth > availableWidth.value && totalWidth > 0 {
                let scale = availableWidth.value / totalWidth
                columnWidths = columnWidths.map { PDF.UserSpace.Width($0.value * scale) }
            }

            return columnWidths
        }

        // MARK: - Row Height Calculation

        /// Calculate row heights from measured content.
        ///
        /// For rows with rowspan > 1, the height is distributed across the spanned rows.
        public func calculateRowHeights(
            columnWidths: [PDF.UserSpace.Width],
            cellPadding: PDF.UserSpace.Unit
        ) -> [PDF.UserSpace.Height] {
            // Count total rows across all sections
            let totalRows = sections.reduce(0) { $0 + $1.rows.count }
            guard totalRows > 0 else { return [] }

            // Initialize with minimum heights
            let minHeight = cellPadding * 2
            var rowHeights = Array(repeating: PDF.UserSpace.Height(minHeight), count: totalRows)

            // Track which heights have been set by rowspan cells
            var rowSpanHeights: [Int: PDF.UserSpace.Height] = [:]

            var globalRow = 0
            for section in sections {
                for row in section.rows {
                    var col = 0
                    for cell in row.cells {
                        if cell.rowspan == 1 {
                            // Single-row cell - update max height for this row
                            let contentHeight = cell.measuredHeight.value + cellPadding * 2
                            if contentHeight > rowHeights[globalRow].value {
                                rowHeights[globalRow] = PDF.UserSpace.Height(contentHeight)
                            }
                        } else {
                            // Multi-row cell - track for later distribution
                            let requiredHeight = cell.measuredHeight.value + cellPadding * 2
                            let key = globalRow * 1000 + cell.rowspan // Unique key for this span
                            if let existing = rowSpanHeights[key] {
                                if requiredHeight > existing.value {
                                    rowSpanHeights[key] = PDF.UserSpace.Height(requiredHeight)
                                }
                            } else {
                                rowSpanHeights[key] = PDF.UserSpace.Height(requiredHeight)
                            }
                        }
                        col += cell.colspan
                    }
                    globalRow += 1
                }
            }

            // Distribute rowspan heights
            for (key, height) in rowSpanHeights {
                let startRow = key / 1000
                let span = key % 1000
                let endRow = min(startRow + span, totalRows)

                // Calculate current total height of spanned rows
                let currentTotal = (startRow..<endRow).reduce(PDF.UserSpace.Unit(0)) {
                    $0 + rowHeights[$1].value
                }

                // If cell needs more height, distribute excess evenly
                if height.value > currentTotal {
                    let excess = height.value - currentTotal
                    let perRow = excess / PDF.UserSpace.Unit(span)
                    for r in startRow..<endRow {
                        rowHeights[r] = PDF.UserSpace.Height(rowHeights[r].value + perRow)
                    }
                }
            }

            return rowHeights
        }

        // MARK: - Span Grid Building

        /// Build a span grid for tracking occupied cells.
        ///
        /// Returns a 2D array where `grid[row][col]` is non-nil if that cell
        /// is occupied by a rowspan from a previous row.
        public func buildSpanGrid() -> [[PDF.HTML.Context.Table.CellSpan?]] {
            let totalRows = sections.reduce(0) { $0 + $1.rows.count }
            guard totalRows > 0, columnCount > 0 else { return [] }

            var grid = Array(
                repeating: Array<PDF.HTML.Context.Table.CellSpan?>(repeating: nil, count: columnCount),
                count: totalRows
            )

            var globalRow = 0
            for section in sections {
                for row in section.rows {
                    var col = 0

                    // Skip cells already occupied by rowspan
                    while col < columnCount && grid[globalRow][col] != nil {
                        col += 1
                    }

                    for cell in row.cells {
                        // Skip occupied cells
                        while col < columnCount && grid[globalRow][col] != nil {
                            col += 1
                        }

                        guard col < columnCount else { break }

                        // Mark cells occupied by this cell's span
                        if cell.rowspan > 1 || cell.colspan > 1 {
                            let span = PDF.HTML.Context.Table.CellSpan(
                                originRow: globalRow,
                                originColumn: col,
                                rowSpan: cell.rowspan,
                                colSpan: cell.colspan
                            )

                            for r in globalRow..<min(globalRow + cell.rowspan, totalRows) {
                                for c in col..<min(col + cell.colspan, columnCount) {
                                    // Don't mark the origin cell itself
                                    if r != globalRow || c != col {
                                        grid[r][c] = span
                                    }
                                }
                            }
                        }

                        col += cell.colspan
                    }

                    globalRow += 1
                }
            }

            return grid
        }
    }
}
