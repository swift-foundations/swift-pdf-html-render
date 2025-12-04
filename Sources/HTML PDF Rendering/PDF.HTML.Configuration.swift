// PDF.HTML.Configuration.swift
// Configuration for HTML to PDF transformation

import PDF_Rendering
import PDF_Standard

/// Configuration for HTML to PDF transformation.
///
/// Controls page layout, typography, and spacing during transformation.
extension PDF.HTML {
    public struct Configuration: Sendable {
        // MARK: - Page Layout

        /// Paper size
        public var paperSize: PDF.UserSpace.Rectangle

        /// Page margins
        public var margins: PDF.UserSpace.EdgeInsets

        // MARK: - Typography

        /// Default font
        public var defaultFont: PDF.Font

        /// Default font size in points
        public var defaultFontSize: PDF.UserSpace.Unit

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

        /// Media box (same as paper size, for use with PDF.Context)
        public var mediaBox: PDF.UserSpace.Rectangle {
            paperSize
        }

        /// Content width (paper width minus margins)
        public var contentWidth: PDF.UserSpace.Unit {
            PDF.UserSpace.Unit(paperSize.width.value) - margins.horizontal
        }

        /// Content height (paper height minus margins)
        public var contentHeight: PDF.UserSpace.Unit {
            PDF.UserSpace.Unit(paperSize.height.value) - margins.vertical
        }

        // MARK: - Init

        public init(
            paperSize: PDF.UserSpace.Rectangle = .a4,
            margins: PDF.UserSpace.EdgeInsets = .init(all: 72),
            defaultFont: PDF.Font = .helvetica,
            defaultFontSize: PDF.UserSpace.Unit = 12,
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
        public func headingSize(level: Int) -> PDF.UserSpace.Unit {
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
}
