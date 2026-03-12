// PDF.HTML.Configuration.Viewer.View.swift
// View area configuration

import ISO_32000

extension PDF.HTML.Configuration.Viewer {
    /// View area configuration.
    public struct View: Sendable, Equatable {
        /// Page boundary for display area
        public var area: ISO_32000.Page.Boundary

        /// Page boundary for clipping display
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
