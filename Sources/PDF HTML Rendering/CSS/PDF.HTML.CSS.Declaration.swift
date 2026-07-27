// PDF.HTML.CSS.Declaration.swift
// A single `property: value` pair inside a CSS rule's declaration block.

import PDF_Rendering

extension PDF.HTML.CSS {
    /// A CSS declaration — property name and value, both as strings.
    ///
    /// Phase 1 defers value-grammar parsing to Commit 4's per-property
    /// modifier dispatchers (e.g., line-height accepts `<number>`,
    /// `<length>`, `<percentage>`, or `normal`; each is parsed at
    /// dispatch time against the property-specific value grammar).
    /// Storing the raw value string here keeps the parser
    /// property-agnostic.
    public struct Declaration: Sendable, Equatable {
        /// Property name (lowercased — CSS property names are
        /// case-insensitive per CSS Syntax §4).
        public var property: String

        /// Value as a trimmed string. Preserves internal whitespace
        /// (for multi-token values like `"sans-serif, Helvetica"`).
        public var value: String

        public init(property: String, value: String) {
            self.property = property
            self.value = value
        }
    }
}
