// PDF.HTML._AnyViewContent.swift
// Dynamic dispatch protocol — workaround for `as?` cast failures on conditional conformances

import HTML_Renderable

/// Marker protocol for HTML.AnyView dynamic dispatch.
///
/// HTML.AnyView does NOT conform to PDF.HTML.View (would cause infinite recursion).
/// Instead, the worklist interpreter uses this protocol for terminal dispatch.
package protocol _AnyViewContent {
    /// Render the wrapped view using dynamic dispatch.
    func _renderAnyViewDynamically(context: inout PDF.HTML.Context)
}
