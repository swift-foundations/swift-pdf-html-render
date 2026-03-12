// PDF.HTML.Context.Table.Deferred.Cell.swift
// Cell bounds for border drawing, captured at cell creation time

import PDF_Rendering

extension PDF.HTML.Context.Table.Deferred {
    /// Cell bounds for border drawing (captured at cell creation time)
    public struct Cell {
        let x: PDF.UserSpace.X
        let y: PDF.UserSpace.Y
        let width: PDF.UserSpace.Width
    }
}
