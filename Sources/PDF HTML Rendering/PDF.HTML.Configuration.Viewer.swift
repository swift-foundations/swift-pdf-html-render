// PDF.HTML.Configuration.Viewer.swift
// PDF viewer preferences configuration

import ISO_32000

extension PDF.HTML.Configuration {
    /// PDF viewer preferences configuration.
    ///
    /// Controls how the document is presented when opened in a PDF viewer.
    /// All defaults match the ISO 32000 PDF specification.
    public struct Viewer: Sendable, Equatable {
        /// Whether to hide the viewer toolbar when document is active
        public var hideToolbar: Bool

        /// Whether to hide the viewer menu bar when document is active
        public var hideMenubar: Bool

        /// Whether to hide UI elements in the document window
        public var hideWindowUI: Bool

        /// Whether to resize document window to fit first page
        public var fitWindow: Bool

        /// Whether to center document window on screen
        public var centerWindow: Bool

        /// Whether to display document title (vs filename) in window title bar
        public var displayDocTitle: Bool

        /// Page mode after exiting full-screen mode
        public var nonFullScreenPageMode: ISO_32000.NonFullScreenPageMode

        /// Reading direction (affects page positioning in two-up mode)
        public var direction: ISO_32000.Direction

        /// View area and clipping settings
        public var view: View

        /// Print area, clipping, and scaling settings
        public var print: Print

        public init(
            hideToolbar: Bool = false,
            hideMenubar: Bool = false,
            hideWindowUI: Bool = false,
            fitWindow: Bool = false,
            centerWindow: Bool = false,
            displayDocTitle: Bool = false,
            nonFullScreenPageMode: ISO_32000.NonFullScreenPageMode = .useNone,
            direction: ISO_32000.Direction = .leftToRight,
            view: View = .init(),
            print: Print = .init()
        ) {
            self.hideToolbar = hideToolbar
            self.hideMenubar = hideMenubar
            self.hideWindowUI = hideWindowUI
            self.fitWindow = fitWindow
            self.centerWindow = centerWindow
            self.displayDocTitle = displayDocTitle
            self.nonFullScreenPageMode = nonFullScreenPageMode
            self.direction = direction
            self.view = view
            self.print = print
        }
    }
}
