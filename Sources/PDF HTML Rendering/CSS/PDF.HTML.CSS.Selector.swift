// PDF.HTML.CSS.Selector.swift
// CSS selectors recognized in Phase 1.
//
// Phase 1 supports only type and universal selectors. Class, ID,
// attribute, pseudo-class, pseudo-element, and combinator selectors
// are parsed-but-classified as `.unsupported` so they match nothing
// per CSS Selectors §3.1 "unsupported selector matches nothing".
// Phase 2 introduces the full selector engine.

import PDF_Rendering

extension PDF.HTML.CSS {
    /// A single CSS selector (one entry in the comma-separated list
    /// preceding a `{ ... }` declaration block).
    public enum Selector: Sendable, Equatable {
        /// Type selector — matches the element with the given tag name.
        /// CSS Selectors §3.1. Tag name is stored lowercased for HTML
        /// case-insensitive matching.
        case type(String)

        /// Universal selector — matches any element. CSS Selectors §3.2.
        case universal

        /// Any selector Phase 1 does not implement (class, ID, attribute,
        /// pseudo, combinator, nesting). Stored verbatim so consumers
        /// (and tests) can introspect parse output without crashing.
        /// Matches nothing in Phase 1's selector-match step.
        case unsupported(String)
    }
}
