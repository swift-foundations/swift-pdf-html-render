import PDF_Rendering

extension PDF.HTML.Context.Table {

    public struct Header: Sendable {

        public var cells: [Cell]?

        public var isCapturing: Bool = false

        public var pendingCells: [Cell] = []

        public var rowHeight: PDF.UserSpace.Height = .zero
    }
}

extension PDF.HTML.Context.Table.Header {

    public var hasHeader: Bool { cells != nil && !(cells?.isEmpty ?? true) }

    public mutating func finalizeCapture() {
        if !pendingCells.isEmpty {
            cells = pendingCells
            pendingCells = []
        }
        isCapturing = false
    }

    public mutating func startCapturing() {
        isCapturing = true
        pendingCells = []
    }

    public mutating func addCell(_ cell: Cell) {
        if isCapturing {
            pendingCells.append(cell)
        }
    }
}
