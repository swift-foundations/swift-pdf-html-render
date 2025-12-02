// HTML.Configuration.swift

public import PDF_Rendering
public import HTML_Renderable

extension HTML {
    /// Configuration for HTML to PDF conversion
    public struct Configuration: Sendable {
        /// Paper size for the PDF
        public var paperSize: PDF.PaperSize

        /// Page margins
        public var margins: PDF.EdgeInsets

        /// Default font for text
        public var defaultFont: PDF.Font

        /// Default font size in points
        public var defaultFontSize: Double

        /// Default text color
        public var defaultColor: PDF.Color

        /// CSS support level
        public var cssSupport: CSSSupport

        /// Line height multiplier
        public var lineHeight: Double

        /// Create a configuration
        public init(
            paperSize: PDF.PaperSize = .a4,
            margins: PDF.EdgeInsets = .standard,
            defaultFont: PDF.Font = .helvetica,
            defaultFontSize: Double = 12,
            defaultColor: PDF.Color = .black,
            cssSupport: CSSSupport = .basic,
            lineHeight: Double = 1.2
        ) {
            self.paperSize = paperSize
            self.margins = margins
            self.defaultFont = defaultFont
            self.defaultFontSize = defaultFontSize
            self.defaultColor = defaultColor
            self.cssSupport = cssSupport
            self.lineHeight = lineHeight
        }

        /// Default configuration
        public static let `default` = Configuration()
    }
}

// MARK: - CSS Support Level

extension HTML.Configuration {
    /// CSS support level for conversion
    public enum CSSSupport: Sendable {
        /// No CSS support - use defaults only
        case none

        /// Basic CSS support:
        /// - font-size
        /// - color
        /// - font-weight (bold)
        /// - font-style (italic)
        /// - margin
        /// - padding
        /// - text-align
        /// - background-color
        /// - border (basic)
        case basic
    }
}

// MARK: - Heading Sizes

extension HTML.Configuration {
    /// Font size scale for heading levels
    public func headingSize(level: Int) -> Double {
        switch level {
        case 1: return defaultFontSize * 2.0      // h1 = 24pt for 12pt base
        case 2: return defaultFontSize * 1.5      // h2 = 18pt
        case 3: return defaultFontSize * 1.17     // h3 = 14pt
        case 4: return defaultFontSize * 1.0      // h4 = 12pt
        case 5: return defaultFontSize * 0.83     // h5 = 10pt
        case 6: return defaultFontSize * 0.67     // h6 = 8pt
        default: return defaultFontSize
        }
    }
}
