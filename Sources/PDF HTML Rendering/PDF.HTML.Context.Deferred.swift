// PDF.HTML.Context.Deferred.swift
// Deferred render operation for sticky headers

extension PDF.HTML.Context {
    /// Deferred render operation for sticky headers
    public struct Deferred: @unchecked Sendable {
        /// Closure that renders the deferred content
        ///
        /// Note: Not marked @Sendable because rendering is single-threaded and synchronous.
        /// The closure captures generic view types that aren't Sendable.
        public let render: (inout PDF.HTML.Context) -> Void
        /// Measured height of the deferred content
        public let measuredHeight: PDF.UserSpace.Height
    }
}
