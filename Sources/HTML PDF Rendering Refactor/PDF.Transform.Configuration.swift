// PDFTransformConfiguration.swift
// Configuration for HTML to PDF transformation

import PDF_Rendering

/// Configuration for HTML to PDF transformation.
///
/// Controls page layout, typography, and spacing during transformation.
public struct PDFTransformConfiguration: Sendable {
    // MARK: - Page Layout
    
    /// Paper size
    public var paperSize: PDF.PaperSize
    
    /// Page margins
    public var margins: PDF.EdgeInsets
    
    // MARK: - Typography
    
    /// Default font
    public var defaultFont: PDF.Font
    
    /// Default font size in points
    public var defaultFontSize: Double
    
    /// Default text color
    public var defaultColor: PDF.Color
    
    /// Line height multiplier
    public var lineHeight: Double
    
    // MARK: - Spacing
    
    /// Paragraph spacing (multiplier of font size)
    public var paragraphSpacing: Double
    
    /// Heading spacing (multiplier of heading size)
    public var headingSpacing: Double
    
    // MARK: - Computed
    
    /// Content width (paper width minus margins)
    public var contentWidth: Double {
        paperSize.width - margins.left - margins.right
    }
    
    /// Content height (paper height minus margins)
    public var contentHeight: Double {
        paperSize.height - margins.top - margins.bottom
    }
    
    // MARK: - Init
    
    public init(
        paperSize: PDF.PaperSize = .a4,
        margins: PDF.EdgeInsets = .init(all: 72),
        defaultFont: PDF.Font = .helvetica,
        defaultFontSize: Double = 12,
        defaultColor: PDF.Color = .black,
        lineHeight: Double = 1.4,
        paragraphSpacing: Double = 0.5,
        headingSpacing: Double = 0.8
    ) {
        self.paperSize = paperSize
        self.margins = margins
        self.defaultFont = defaultFont
        self.defaultFontSize = defaultFontSize
        self.defaultColor = defaultColor
        self.lineHeight = lineHeight
        self.paragraphSpacing = paragraphSpacing
        self.headingSpacing = headingSpacing
    }
    
    // MARK: - Heading Sizes
    
    /// Font size for heading level (1-6)
    public func headingSize(level: Int) -> Double {
        switch level {
        case 1: return defaultFontSize * 2.0
        case 2: return defaultFontSize * 1.5
        case 3: return defaultFontSize * 1.17
        case 4: return defaultFontSize * 1.0
        case 5: return defaultFontSize * 0.83
        case 6: return defaultFontSize * 0.67
        default: return defaultFontSize
        }
    }
}

// MARK: - Typealiases

extension PDF {
    /// Typealias for PDFTransformConfiguration
    public typealias Configuration = PDFTransformConfiguration
}

extension PDFTransform {
    /// Typealias for Configuration
    public typealias Configuration = PDFTransformConfiguration
}

/// Namespace for HTML to PDF transformation (deprecated, use PDFTransform)
public typealias HTMLToPDF = PDFTransform
