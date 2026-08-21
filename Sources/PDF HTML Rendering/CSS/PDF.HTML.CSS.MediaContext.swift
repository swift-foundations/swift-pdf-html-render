import PDF_Rendering

extension PDF.HTML.CSS {

    public enum MediaContext: Sendable, Equatable {
        case unconditional
        case printIncludes
        case screenOnly
        case bareFeature
        case other
    }
}
