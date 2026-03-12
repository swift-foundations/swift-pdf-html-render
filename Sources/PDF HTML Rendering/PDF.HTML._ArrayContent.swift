// PDF.HTML._ArrayContent.swift
// Dynamic dispatch protocol — workaround for `as?` cast failures on conditional conformances

import HTML_Renderable

/// Marker protocol for _Array dynamic dispatch.
///
/// Arrays have no Mirror-based detection in Phase 1, so this protocol
/// is essential for Phase 2 `as?` dispatch.
package protocol _ArrayContent {
    /// Render all elements in the array using dynamic dispatch.
    func _renderArrayDynamically(context: inout PDF.HTML.Context)
}
