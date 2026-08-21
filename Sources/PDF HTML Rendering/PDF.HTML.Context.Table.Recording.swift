import PDF_Rendering

extension PDF.HTML.Context.Table {

    struct Recording: @unchecked Sendable {

        var commands: [Command] = []

        let savedY: PDF.UserSpace.Y

        var elementDepth: Int = 0

        var pushedIsVoid: [Bool] = []

        var columnCount: Int = 0

        var pendingColspan: Int = 1

        var pendingCellWidthPercent: Double?

        var pendingCellHorizontalPadding: Double = 0

        var columnWidthWeights: [Int: Double] = [:]

        var columnMinContentWidths: [Int: PDF.UserSpace.Width] = [:]
        var columnMaxContentWidths: [Int: PDF.UserSpace.Width] = [:]

        var cellsPushedInCurrentRow: Int = 0

        var topLevelRowIndex: Int = 0

        var currentCellColumn: Int? = nil
        var currentCellMinWidth: PDF.UserSpace.Width = .init(0)
        var currentCellMaxWidth: PDF.UserSpace.Width = .init(0)

        var currentCellPadding: Double = 0

        var currentLineWidth: PDF.UserSpace.Width = .init(0)
    }
}
