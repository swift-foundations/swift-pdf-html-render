// PDF.HTML.Context.Table.Header.swift
// Header capture and repetition state for multi-page tables

import PDF_Rendering

extension PDF.HTML.Context.Table {
    /// Manages header capture and repetition for multi-page tables
    public struct Header: Sendable {
        /// Captured header cells (nil if no header in table)
        public var cells: [Cell]?

        /// Whether we're currently inside a thead section (capturing content)
        public var isCapturing: Bool = false

        /// Temporary storage for cells being captured during thead rendering
        public var pendingCells: [Cell] = []

        /// Height of the header row (for page break calculations)
        public var rowHeight: PDF.UserSpace.Height = .zero
    }
}

extension PDF.HTML.Context.Table.Header {
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
