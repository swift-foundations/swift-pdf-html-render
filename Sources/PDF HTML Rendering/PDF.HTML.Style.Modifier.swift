import PDF_Rendering

extension PDF.HTML.Style {

    public protocol Modifier {

        func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration)
    }
}
