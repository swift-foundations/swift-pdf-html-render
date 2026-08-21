import PDF_Rendering

extension PDF.HTML.CSS {

    public enum Selector: Sendable, Equatable {

        case type(String)

        case universal

        case unsupported(String)
    }
}
