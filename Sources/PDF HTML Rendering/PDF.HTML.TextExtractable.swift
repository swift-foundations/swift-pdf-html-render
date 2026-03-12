// PDF.HTML.TextExtractable.swift
// Protocol and helpers for efficient text extraction from HTML content

// MARK: - Text Extraction Protocol (Performance Optimization)

extension PDF.HTML {
    /// Protocol for types that can efficiently extract text for PDF table headers.
    /// Conforming to this protocol avoids expensive Mirror reflection.
    public protocol TextExtractable {
        /// The extracted text content for PDF rendering
        var pdfExtractedText: String { get }
    }
}

extension String: PDF.HTML.TextExtractable {
    @inlinable
    public var pdfExtractedText: String { self }
}

// MARK: - Header Text Extraction

extension HTML.Element.Tag {
    /// Extract plain text content from cell for header repetition
    static func extractCellText<CellContent>(from content: CellContent) -> String {
        // Fast path: Check TextExtractable protocol (avoids Mirror reflection)
        if let extractable = content as? PDF.HTML.TextExtractable {
            return extractable.pdfExtractedText
        }

        // Fallback: Use Mirror to recursively find string content
        let mirror = Mirror(reflecting: content)

        // Check for HTML.Element or other containers with text
        for child in mirror.children {
            // Check protocol first for child values
            if let extractable = child.value as? PDF.HTML.TextExtractable {
                return extractable.pdfExtractedText
            }
            // Recursively check nested content (using Any to avoid generic issues)
            let nested = extractCellTextFromAny(child.value)
            if !nested.isEmpty {
                return nested
            }
        }

        // Fallback: use string description if it looks like content
        let description = String(describing: content)
        if !description.contains("HTML.Element") && !description.contains("(") && !description.contains("<") {
            return description
        }

        return ""
    }

    /// Helper to extract text from Any type
    static func extractCellTextFromAny(_ value: Any) -> String {
        // Fast path: Check TextExtractable protocol (avoids Mirror reflection)
        if let extractable = value as? PDF.HTML.TextExtractable {
            return extractable.pdfExtractedText
        }

        // Fallback to Mirror
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            if let extractable = child.value as? PDF.HTML.TextExtractable {
                return extractable.pdfExtractedText
            }
            let nested = extractCellTextFromAny(child.value)
            if !nested.isEmpty {
                return nested
            }
        }

        return ""
    }
}
