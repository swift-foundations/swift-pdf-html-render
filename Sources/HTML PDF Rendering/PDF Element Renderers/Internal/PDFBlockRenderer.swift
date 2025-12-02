// PDFBlockRenderer.swift
// Shared utilities for block element rendering

import PDF_Rendering
import HTML_Renderable

/// Renders children as a block element with spacing.
///
/// This helper is used by block-level element renderers to:
/// 1. Flush pending inline runs
/// 2. Add spacing before
/// 3. Render children
/// 4. Flush inline runs from children
/// 5. Add spacing after
///
/// - Parameters:
///   - children: Child elements to render
///   - style: The computed style for the block
///   - context: The PDF rendering context
///   - configuration: The HTML-to-PDF configuration
///   - beforeSpacing: Vertical space to add before the block
///   - afterSpacing: Vertical space to add after the block
public func renderBlock(
    children: [any HTMLToPDFConvertible],
    style: HTML.ComputedStyle,
    context: inout PDF.Context,
    configuration: HTML.Configuration,
    beforeSpacing: Double = 0,
    afterSpacing: Double = 0
) throws {
    // Flush any pending inline runs before this block
    try context.flushInlineRuns()

    // Check for page break and add spacing before
    if beforeSpacing > 0 {
        context.checkPageBreak(needing: beforeSpacing)
        context.advanceY(beforeSpacing)
    }

    // Render children using dynamic dispatch
    for child in children {
        _ = HTML.renderToPDF(child, configuration: configuration, style: style, context: &context)
    }

    // Flush inline runs accumulated by children
    try context.flushInlineRuns()

    // Add spacing after
    if afterSpacing > 0 {
        context.advanceY(afterSpacing)
    }
}

/// Renders children as inline content (no flush).
///
/// This helper is used by inline element renderers to render
/// children without flushing text runs.
///
/// - Parameters:
///   - children: Child elements to render
///   - style: The computed style for the inline content
///   - context: The PDF rendering context
///   - configuration: The HTML-to-PDF configuration
public func renderInline(
    children: [any HTMLToPDFConvertible],
    style: HTML.ComputedStyle,
    context: inout PDF.Context,
    configuration: HTML.Configuration
) {
    for child in children {
        _ = HTML.renderToPDF(child, configuration: configuration, style: style, context: &context)
    }
}
