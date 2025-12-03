// exports.swift
// Public exports for HTML PDF Rendering Refactor

@_exported import HTML_Renderable
@_exported import PDF_Rendering
@_exported import HTML_Standard

// Re-export the main entry points
// - PDF.Content.init(_ html:) - transforms HTML to PDF content
// - PDF.Document.init(_ html:) - creates a PDF document from HTML
// - PDF.Transform - protocol for custom transformation
// - PDF.HTML.Configuration - configuration for transformation
