// PDF.HTML.Context.Table.Grid.swift
// Grid tracking cells occupied by rowspan/colspan

extension PDF.HTML.Context.Table {
    /// Tracks which cells are occupied by rowspan/colspan from other cells
    public struct Grid: Sendable {
        /// `grid[row][column]` is non-nil if that cell is occupied by a spanning cell
        private var grid: [[Span?]] = []

        /// Pre-allocate the grid for known dimensions
        /// Call this when table dimensions are known to avoid dynamic growth during rendering
        public mutating func preallocate(rows: Int, columns: Int) {
            guard rows > 0 && columns > 0 else { return }
            grid = Array(repeating: Array(repeating: nil, count: columns), count: rows)
        }

        /// Check if a cell position is occupied by a span from another cell
        public func isOccupied(row: Int, column: Int) -> Bool {
            guard row < grid.count, column < grid[row].count else { return false }
            return grid[row][column] != nil
        }

        /// Get the span occupying a cell position (nil if not occupied)
        public func span(atRow row: Int, column: Int) -> Span? {
            guard row < grid.count, column < grid[row].count else { return nil }
            return grid[row][column]
        }

        /// Mark cells as occupied by a rowspan/colspan cell
        public mutating func mark(
            fromRow originRow: Int,
            column originColumn: Int,
            rowspan: Int,
            colspan: Int,
            columnCount: Int
        ) {
            let span = Span(
                originRow: originRow,
                originColumn: originColumn,
                rowSpan: rowspan,
                colSpan: colspan
            )

            let requiredRows = originRow + rowspan

            // Batch allocate missing rows (avoid repeated append)
            if grid.count < requiredRows {
                grid.reserveCapacity(requiredRows)
                let missingRows = requiredRows - grid.count
                for _ in 0..<missingRows {
                    grid.append(Array(repeating: nil, count: columnCount))
                }
            }

            // Mark all cells covered by this span (except the origin cell itself)
            for r in originRow..<requiredRows {
                // Extend row to required column count if needed (single allocation)
                if grid[r].count < columnCount {
                    grid[r].append(contentsOf: Array(repeating: nil, count: columnCount - grid[r].count))
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
}
