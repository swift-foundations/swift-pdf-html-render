// PDF.HTML.CSS.MediaContext.swift
// Print-media-aware @media classification.

import PDF_Rendering

//
// Per CSS Media Queries §2.3, PDF rendering is the `print` media type.
// Phase 1 classifies @media queries into 5 disjoint variants so the
// cascade-apply loop (Commit 4) can filter rules without evaluating
// individual media features (which is Phase 2 work).

extension PDF.HTML.CSS {
    /// Classification of an `@media` query against the PDF/`print`
    /// rendering target.
    ///
    /// - `unconditional`: rule is outside any `@media` block.
    ///   Applies always.
    /// - `printIncludes`: rule is inside `@media print`,
    ///   `@media print and (...)`, `@media all`, or any comma-list
    ///   that includes `print` or `all`. Applies for PDF.
    /// - `screenOnly`: rule is inside `@media screen`,
    ///   `@media only screen and (...)`, or any query restricted to
    ///   `screen` without `print`/`all`. Does NOT apply for PDF.
    /// - `bareFeature`: rule is inside `@media (feature-only)` with
    ///   no media-type prefix (e.g., `@media (min-width: 832px)`).
    ///   Per Phase 1 disposition: no viewport ⇒ no match (SKIP).
    ///   Phase 2 will introduce print-equivalent viewport evaluation.
    /// - `other`: rule is inside an `@media` query with a media type
    ///   that is neither `print`, `screen`, nor `all` (e.g., `tv`,
    ///   `speech`). Does NOT apply for PDF.
    public enum MediaContext: Sendable, Equatable {
        case unconditional
        case printIncludes
        case screenOnly
        case bareFeature
        case other
    }
}
