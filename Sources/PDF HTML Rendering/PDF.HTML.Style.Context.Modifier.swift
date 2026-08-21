import PDF_Rendering

extension PDF.HTML.Style.Context {

    public protocol Modifier {

        func apply(to context: inout PDF.HTML.Context)
    }
}
