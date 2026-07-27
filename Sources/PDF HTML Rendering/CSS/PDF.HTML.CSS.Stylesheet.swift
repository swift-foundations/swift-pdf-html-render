// PDF.HTML.CSS.Stylesheet.swift
// Parsed `<style>` block contents — a source-order-preserved list of CSS rules.

import PDF_Rendering

extension PDF.HTML.CSS {
    /// A parsed CSS stylesheet (from one or more `<style>` blocks).
    ///
    /// Rules are stored in source order. Phase 1's cascade-resolution
    /// strategy at `_pushElement` is source-order-last-wins per CSS Cascade
    /// §6.4.4; preserving insertion order here is load-bearing for that
    /// invariant.
    public struct Stylesheet: Sendable, Equatable {
        /// Rules in source order — parser MUST preserve insertion order.
        public var rules: [Rule]

        public init(rules: [Rule] = []) {
            self.rules = rules
        }
    }
}
