// Paragraph+PDF.HTML.View.swift
// <p> element transformation

import HTML_Standard
import HTML_Renderable
import PDF_Rendering

// Note: Paragraph rendering is handled by HTML.Element via flow-based rendering.
// The HTML.Element extension checks Tag.flow and renders as block for <p>.
// Custom paragraph handling (spacing, etc.) can be added here if needed.
