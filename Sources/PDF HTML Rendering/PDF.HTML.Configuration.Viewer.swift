import ISO_32000

extension PDF.HTML.Configuration {

    public struct Viewer: Sendable, Equatable {

        public var hideToolbar: Bool

        public var hideMenubar: Bool

        public var hideWindowUI: Bool

        public var fitWindow: Bool

        public var centerWindow: Bool

        public var displayDocTitle: Bool

        public var nonFullScreenPageMode: ISO_32000.NonFullScreenPageMode

        public var direction: ISO_32000.Direction

        public var view: View

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
