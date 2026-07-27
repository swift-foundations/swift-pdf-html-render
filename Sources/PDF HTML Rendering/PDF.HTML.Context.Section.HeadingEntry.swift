// PDF.HTML.Context.Section.HeadingEntry.swift
// Heading entry for bookmark generation

extension PDF.HTML.Context.Section {
    /// Entry for a heading collected during rendering.
    public struct HeadingEntry: Sendable {
        public let level: Int
        public let text: String
        public let pageNumber: Int
        public let yPosition: PDF.UserSpace.Y

        public init(level: Int, text: String, pageNumber: Int, yPosition: PDF.UserSpace.Y) {
            self.level = level
            self.text = text
            self.pageNumber = pageNumber
            self.yPosition = yPosition
        }
    }
}
