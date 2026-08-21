import ISO_32000

extension PDF.HTML.Configuration.Viewer {

    public struct Print: Sendable, Equatable {

        public var area: ISO_32000.Page.Boundary

        public var clip: ISO_32000.Page.Boundary

        public var scaling: ISO_32000.Print.Scaling

        public init(
            area: ISO_32000.Page.Boundary = .cropBox,
            clip: ISO_32000.Page.Boundary = .cropBox,
            scaling: ISO_32000.Print.Scaling = .appDefault
        ) {
            self.area = area
            self.clip = clip
            self.scaling = scaling
        }
    }
}
