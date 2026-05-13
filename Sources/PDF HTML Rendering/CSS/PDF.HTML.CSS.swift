// PDF.HTML.CSS.swift
// Namespace for the Phase 1 CSS-cascade parsing infrastructure.

import PDF_Rendering
//
// Phase 1 implements a type-selector-only stylesheet parser with
// print-media-aware @media classification. See
// Research/css-cascade-architectural-gap-2026-05-13.md for the staged
// remediation framing and Phase 2 trigger conditions.

extension PDF.HTML {
    /// CSS-cascade infrastructure for the PDF rendering path.
    ///
    /// Phase 1 scope:
    /// - `Stylesheet`: parsed `<style>` block contents as a rule list
    /// - `Stylesheet.Rule`: a single CSS rule (selector list + declaration block + media context)
    /// - `Stylesheet.Selector`: type / universal / unsupported
    /// - `Stylesheet.Declaration`: property-name + value-as-string (value-grammar parsing deferred to per-property modifier dispatchers)
    /// - `Stylesheet.MediaContext`: print-media-aware @media classification
    /// - `Stylesheet.Parser`: recursive-descent parser following the institute idiom established by `W3C_SVG2.Paths.Path.Parser`
    public enum CSS {}
}
