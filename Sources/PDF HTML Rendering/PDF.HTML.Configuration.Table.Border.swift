import PDF_Rendering
import PDF_Standard

extension PDF.HTML.Configuration.Table {

    public struct Border: Sendable, Equatable {

        public var color: PDF.Color

        public var width: PDF.UserSpace.Size<1>

        public init(
            color: PDF.Color = .gray(0.3),
            width: PDF.UserSpace.Size<1> = 0
        ) {
            self.color = color
            self.width = width
        }
    }
}
