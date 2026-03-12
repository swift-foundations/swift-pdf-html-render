// PDF.HTML._HTMLStyledContent.swift
// Dynamic dispatch protocol — workaround for `as?` cast failures on conditional conformances

import HTML_Renderable

/// Marker protocol for HTML.Styled dynamic dispatch.
///
/// Used by `renderFlattenedStyledContent` to iteratively peel consecutive
/// Styled layers and apply their properties without stack overflow.
package protocol _HTMLStyledContent {
    /// Apply this styled element's property to the context.
    /// Returns captured break flags.
    func applyStyle(to context: inout PDF.HTML.Context) -> PDF.HTML.Context.Break

    /// Get the wrapped content as _HTMLStyledContent if it is one (avoids existential boxing).
    var wrappedStyledContent: (any _HTMLStyledContent)? { get }

    /// Render the wrapped content directly (avoids existential boxing of content).
    func renderWrappedContent(context: inout PDF.HTML.Context)
}
