// PDF.HTML.Context.Break.swift
// Break flag capture from style modifier application

extension PDF.HTML.Context {
    /// Captured break flags from style modifier application.
    ///
    /// Style modifiers communicate break intent by setting flags on the context.
    /// `captureBreakFlags()` atomically reads and resets them, returning this value.
    public struct Break: Sendable {
        public var avoidAfter: Bool
        public var forceAfter: Bool
        public var avoidInside: Bool

        public static let none = Break(avoidAfter: false, forceAfter: false, avoidInside: false)
    }
}
