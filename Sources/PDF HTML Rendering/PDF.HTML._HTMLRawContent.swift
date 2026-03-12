// PDF.HTML._HTMLRawContent.swift
// Dynamic dispatch protocol — workaround for `as?` cast failures on conditional conformances

import HTML_Renderable

/// Marker protocol for HTML.Raw (renders as empty in PDF context).
///
/// Raw HTML content (like `<script>...</script>`) doesn't have a meaningful
/// PDF representation and is safely ignored during PDF rendering.
package protocol _HTMLRawContent {}
