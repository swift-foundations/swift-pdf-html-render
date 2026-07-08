// PDF.HTML.Context.Snapshot.swift
// PDF context style snapshot for deferred rendering

extension PDF.HTML.Context {
    /// Snapshot of PDF context state for restoration during deferred rendering
    ///
    /// **Important**: Only captures and restores **style** (font, color, etc.),
    /// NOT the layout position. The deferred content should render at the
    /// current Y position when the closure executes, not where the header
    /// was originally encountered.
    public struct Snapshot: Sendable {
        public let style: PDF.Context.Style.Resolved

        public init(from context: PDF.Context) {
            self.style = context.style
        }
    }
}

extension PDF.HTML.Context.Snapshot {
    public func restore(to context: inout PDF.Context) {
        context.style = style
        // NOTE: Do NOT restore layout.box - the deferred content should
        // render at the current position, not the original position
    }
}
