// PDF.HTML.Configuration.Annotation.swift
// Annotation configuration

extension PDF.HTML.Configuration {
    /// Annotation configuration.
    public struct Annotation: Sendable, Equatable {
        /// Border settings for annotations
        public var border: Border

        public init(
            border: Border = .init()
        ) {
            self.border = border
        }
    }
}
