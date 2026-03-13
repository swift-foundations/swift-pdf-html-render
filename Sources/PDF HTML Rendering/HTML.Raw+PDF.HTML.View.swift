// HTML.Raw+PDF.HTML.View.swift
// Raw HTML is ignored in PDF rendering

import HTML_Renderable

// MARK: - HTML.Raw Dynamic Dispatch Support

/// HTML.Raw conforms to _HTMLRawContent so it can be recognized during dynamic dispatch.
///
/// Raw HTML content (like `<script>...</script>` or inline HTML in markdown)
/// doesn't have a meaningful PDF representation and is safely ignored.
extension HTML.Raw: _HTMLRawContent {}
