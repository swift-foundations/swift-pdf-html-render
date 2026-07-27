// PDF.HTML.CSS.Rule.swift
// A single CSS rule — selector list + declaration block + media context.

import PDF_Rendering

extension PDF.HTML.CSS {
    /// A single CSS rule.
    ///
    /// `selectors` is the comma-separated list before `{`. `declarations`
    /// are the `property: value;` pairs inside `{ ... }`. `mediaContext`
    /// captures whether this rule was inside an `@media` block; rules
    /// outside `@media` carry `.unconditional`.
    public struct Rule: Sendable, Equatable {
        public var selectors: [Selector]
        public var declarations: [Declaration]
        public var mediaContext: MediaContext

        public init(
            selectors: [Selector],
            declarations: [Declaration],
            mediaContext: MediaContext = .unconditional
        ) {
            self.selectors = selectors
            self.declarations = declarations
            self.mediaContext = mediaContext
        }
    }
}
