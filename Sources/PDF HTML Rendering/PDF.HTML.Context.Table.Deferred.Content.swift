// PDF.HTML.Context.Table.Deferred.Content.swift
// Content bounds for text rendering within a deferred spanning cell

import PDF_Rendering

extension PDF.HTML.Context.Table.Deferred {
    /// Content bounds for text rendering
    public struct Content {
        let x: PDF.UserSpace.X
        let width: PDF.UserSpace.Width
    }
}
