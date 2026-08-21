import PDF_Rendering

extension W3C_CSS_Multicolumn.BreakBefore: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {

        case .always, .all, .page:
            guard !context.page.isEmpty else { break }
            context.page.new()

        case .left, .right, .recto, .verso:
            guard !context.page.isEmpty else { break }
            context.page.new()

        case .avoid, .avoidPage:
            break

        case .avoidColumn, .column, .avoidRegion, .region:
            break

        case .auto, .global:
            break
        }
    }
}
