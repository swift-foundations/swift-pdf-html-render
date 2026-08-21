import Layout_Primitives
import PDF_Rendering
import Render_Primitives

extension PDF.HTML.Context.Table {

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
