// PDF.HTML.Context.Table.Deferred.swift
// Deferred spanning cell (rowspan > 1) needing content and borders drawn after all rows

import Layout_Primitives
import PDF_Rendering
import Render_Primitives

extension PDF.HTML.Context.Table {
    /// Deferred spanning cells (rowspan > 1) that need content + borders drawn after all rows
    public struct Deferred {
        let origin: Origin
        let column: Int
        let span: Span
        let isHeader: Bool
        let cell: Cell
        let content: Content
        let savedStyle: PDF.Context.Style.Resolved
        let text: String
        let textAlignment: Horizontal.Alignment
    }
}
