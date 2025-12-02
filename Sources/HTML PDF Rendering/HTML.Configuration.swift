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

// MARK: - Element Spacing

extension HTML.Configuration {
    /// Spacing configuration for block elements.
    ///
    /// All values are multipliers relative to the element's font size.
    public struct Spacing: Sendable {
        /// Space before the element (as font size multiplier)
        public var before: Double

        /// Space after the element (as font size multiplier)
        public var after: Double

        public init(before: Double = 0, after: Double = 0) {
            self.before = before
            self.after = after
        }

        public static let none = Spacing()
    }

    /// Spacing for heading levels.
    ///
    /// Returns before/after spacing as multipliers of the heading's font size.
    public func headingSpacing(level: Int) -> Spacing {
        switch level {
        case 1: return Spacing(before: 1.0, after: 0.5)
        case 2: return Spacing(before: 0.9, after: 0.4)
        case 3: return Spacing(before: 0.8, after: 0.35)
        case 4: return Spacing(before: 0.7, after: 0.3)
        case 5: return Spacing(before: 0.6, after: 0.25)
        case 6: return Spacing(before: 0.5, after: 0.2)
        default: return Spacing(before: 0.5, after: 0.25)
        }
    }

    /// Spacing for paragraph elements.
    public var paragraphSpacing: Spacing {
        Spacing(before: 0, after: 0.8)
    }

    /// Spacing for blockquote elements.
    public var blockquoteSpacing: Spacing {
        Spacing(before: 0.5, after: 0.5)
    }

    /// Spacing for preformatted text elements.
    public var preformattedSpacing: Spacing {
        Spacing(before: 0.5, after: 0.5)
    }

    /// Spacing for list elements (ul, ol).
    public var listSpacing: Spacing {
        Spacing(before: 0.5, after: 0.5)
    }

    /// Spacing for list items.
    public var listItemSpacing: Spacing {
        Spacing(before: 0, after: 0.3)
    }

    /// Spacing for table elements.
    public var tableSpacing: Spacing {
        Spacing(before: 0.5, after: 0.5)
    }

    /// Spacing for figure elements.
    public var figureSpacing: Spacing {
        Spacing(before: 0.75, after: 0.75)
    }

    /// Spacing for details/summary elements.
    public var detailsSpacing: Spacing {
        Spacing(before: 0.25, after: 0.5)
    }

    /// Spacing for dialog elements.
    public var dialogSpacing: Spacing {
        Spacing(before: 0.75, after: 0.75)
    }

    /// Spacing for section/article elements.
    public var sectionSpacing: Spacing {
        Spacing(before: 0.5, after: 0.5)
    }

    /// Spacing for header elements.
    public var headerSpacing: Spacing {
        Spacing(before: 0, after: 0.5)
    }

    /// Spacing for footer elements.
    public var footerSpacing: Spacing {
        Spacing(before: 1.0, after: 0)
    }
}

// MARK: - Element Indentation

extension HTML.Configuration {
    /// Indentation for list items in points.
    public var listIndent: Double { 20 }

    /// Indentation for blockquotes in points.
    public var blockquoteIndent: Double { 30 }

    /// Indentation for preformatted text in points.
    public var preformattedIndent: Double { 20 }

    /// Indentation for figure elements in points.
    public var figureIndent: Double { 20 }

    /// Indentation for details elements in points.
    public var detailsIndent: Double { 15 }

    /// Padding for dialog elements in points.
    public var dialogPadding: Double { 15 }

    /// Gap between list marker and content in points.
    public var listMarkerGap: Double { 4 }

    /// Indentation for fieldset elements in points.
    public var fieldsetIndent: Double { 10 }

    /// Spacing for fieldset elements.
    public var fieldsetSpacing: Spacing {
        Spacing(before: 0.5, after: 0.5)
    }
}
