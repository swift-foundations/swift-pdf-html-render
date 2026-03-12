// PDF.HTML+DynamicDispatchProtocols.swift
// Package protocols enabling dynamic dispatch for result builder types

import HTML_Renderable

// MARK: - Dynamic Dispatch Support Protocols
//
// These protocols work around Swift's limitation where `as?` casts fail for
// conditional conformances on deeply nested generic types (SIGBUS in
// `swift_conformsToProtocolMaybeInstantiateSuperclasses`).
//
// Protocols removed as dead code (2026-03-12):
// - _TupleContent: replaced by Rendering._TupleMarker (Phase 0)
// - _ConditionalContent: replaced by Mirror-based isConditionalType (Phase 1)
// - _OptionalContent: replaced by Mirror-based isOptionalType (Phase 1)

/// Marker protocol for HTML.AnyView dynamic dispatch.
///
/// HTML.AnyView does NOT conform to PDF.HTML.View (would cause infinite recursion).
/// Instead, the worklist interpreter uses this protocol for terminal dispatch.
package protocol _AnyViewContent {
    /// Render the wrapped view using dynamic dispatch.
    func _renderAnyViewDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for HTML.Element.Tag dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `HTML.Element.Tag: PDF.HTML.View where Content: PDF.HTML.View`.
package protocol _HTMLElementContent {
    /// Render this element using dynamic dispatch for content.
    func _renderElementDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for HTML.Raw (renders as empty in PDF context).
///
/// Raw HTML content (like `<script>...</script>`) doesn't have a meaningful
/// PDF representation and is safely ignored during PDF rendering.
package protocol _HTMLRawContent {}

/// Marker protocol for HTML.Styled dynamic dispatch.
///
/// Used by `renderFlattenedStyledContent` to iteratively peel consecutive
/// Styled layers and apply their properties without stack overflow.
package protocol _HTMLStyledContent {
    /// Apply this styled element's property to the context.
    /// Returns captured break flags.
    func applyStyle(to context: inout PDF.HTML.Context) -> PDF.HTML.Context.BreakFlags

    /// Get the wrapped content as _HTMLStyledContent if it is one (avoids existential boxing).
    var wrappedStyledContent: (any _HTMLStyledContent)? { get }

    /// Render the wrapped content directly (avoids existential boxing of content).
    func renderWrappedContent(context: inout PDF.HTML.Context)
}

/// Marker protocol for _Array dynamic dispatch.
///
/// Arrays have no Mirror-based detection in Phase 1, so this protocol
/// is essential for Phase 2 `as?` dispatch.
package protocol _ArrayContent {
    /// Render all elements in the array using dynamic dispatch.
    func _renderArrayDynamically(context: inout PDF.HTML.Context)
}
