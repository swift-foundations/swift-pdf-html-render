// PDF.HTML.Configuration.Viewer.Print.swift
// Print configuration

import ISO_32000

extension PDF.HTML.Configuration.Viewer {
    /// Print configuration.
    public struct Print: Sendable, Equatable {
        /// Page boundary for print area
        public var area: ISO_32000.Page.Boundary

        /// Page boundary for clipping print output
        public var clip: ISO_32000.Page.Boundary

        /// Default print scaling behavior
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
