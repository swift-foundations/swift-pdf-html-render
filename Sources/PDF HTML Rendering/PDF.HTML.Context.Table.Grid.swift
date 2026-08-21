extension PDF.HTML.Context.Table {

    public struct Grid: Sendable {

        private var grid: [[Span?]] = []
    }
}

extension PDF.HTML.Context.Table.Grid {

    public mutating func preallocate(rows: Int, columns: Int) {
        guard rows > 0 && columns > 0 else { return }
        grid = Array(repeating: Array(repeating: nil, count: columns), count: rows)
    }

    public func isOccupied(row: Int, column: Int) -> Bool {
        guard row < grid.count, column < grid[row].count else { return false }
        return grid[row][column] != nil
    }

    public func span(atRow row: Int, column: Int) -> Span? {
        guard row < grid.count, column < grid[row].count else { return nil }
        return grid[row][column]
    }

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

        if grid.count < requiredRows {
            grid.reserveCapacity(requiredRows)
            let missingRows = requiredRows - grid.count
            for _ in 0..<missingRows {
                grid.append(Array(repeating: nil, count: columnCount))
            }
        }

        for r in originRow..<requiredRows {

            if grid[r].count < columnCount {
                grid[r].append(
                    contentsOf: Array(repeating: nil, count: columnCount - grid[r].count)
                )
            }

            for c in originColumn..<(originColumn + colspan) {

                if r == originRow && c == originColumn { continue }
                if c < grid[r].count {
                    grid[r][c] = span
                }
            }
        }
    }
}
