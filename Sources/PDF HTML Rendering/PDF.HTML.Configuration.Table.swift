import PDF_Rendering

extension PDF.HTML.Configuration {

    public struct Table: Sendable, Equatable {

        public var cell: Cell

        public var border: Border

        public var headerBackground: PDF.Color?

        public var alternatingRowColor: PDF.Color?

        public init(
            cell: Cell = .init(),
            border: Border = .init(),
            headerBackground: PDF.Color? = .gray(0.9),
            alternatingRowColor: PDF.Color? = nil
        ) {
            self.cell = cell
            self.border = border
            self.headerBackground = headerBackground
            self.alternatingRowColor = alternatingRowColor
        }
    }
}
