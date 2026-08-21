import ISO_32000

extension PDF.HTML.Configuration.Viewer {

    public struct View: Sendable, Equatable {

        public var area: ISO_32000.Page.Boundary

        public var clip: ISO_32000.Page.Boundary

        public init(
            area: ISO_32000.Page.Boundary = .cropBox,
            clip: ISO_32000.Page.Boundary = .cropBox
        ) {
            self.area = area
            self.clip = clip
        }
    }
}
