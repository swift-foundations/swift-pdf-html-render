// Headings+PDF.HTML.View.swift
// <h1> - <h6> element transformations

import HTML_Standard
import HTML_Renderable
import PDF_Rendering

// Note: Heading rendering is handled by HTML.Element via flow-based rendering.
// The HTML.Element extension checks Tag.flow and renders as block for <h1>-<h6>.
// Custom heading handling (font size, spacing, etc.) can be added here if needed.
