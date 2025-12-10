// PDF.HTML.Configuration.swift
// Configuration for HTML to PDF transformation

import Geometry
import PDF_Rendering
import PDF_Standard
import W3C_CSS_Text

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

        /// Line height (CSS line-height property)
        ///
        /// - `.normal`: Uses font metrics to calculate a reasonable line height
        /// - `.multiple(1.5)`: Multiplier of font size
        /// - `.lengthPercentage(.px(18))`: Fixed length
        public var lineHeight: LineHeight

        // MARK: - Spacing

        /// Paragraph spacing (multiplier of font size)
        public var paragraphSpacing: Double

        /// Heading spacing (multiplier of heading size)
        public var headingSpacing: Double

        // MARK: - Table Configuration

        /// Cell padding for table cells
        public var tableCellPadding: PDF.UserSpace.Unit

        /// Border color for table cell edges
        public var tableBorderColor: PDF.Color

        /// Border width for table cell edges
        public var tableBorderWidth: PDF.UserSpace.Unit

        /// Background color for table header cells (nil for transparent)
        public var tableHeaderBackground: PDF.Color?

        /// Alternating row background color (nil for no alternation)
        public var tableAlternatingRowColor: PDF.Color?

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
            defaultFont: PDF.Font = .times,
            defaultFontSize: PDF.UserSpace.Unit = 12,
            defaultColor: PDF.Color = .black,
            lineHeight: LineHeight = .normal,
            paragraphSpacing: Double = 0.5,
            headingSpacing: Double = 0.8,
            tableCellPadding: PDF.UserSpace.Unit = 4,
            tableBorderColor: PDF.Color = .gray(0.3),
            tableBorderWidth: PDF.UserSpace.Unit = 0.5,
            tableHeaderBackground: PDF.Color? = .gray(0.9),
            tableAlternatingRowColor: PDF.Color? = nil
        ) {
            self.paperSize = paperSize
            self.margins = margins
            self.defaultFont = defaultFont
            self.defaultFontSize = defaultFontSize
            self.defaultColor = defaultColor
            self.lineHeight = lineHeight
            self.paragraphSpacing = paragraphSpacing
            self.headingSpacing = headingSpacing
            self.tableCellPadding = tableCellPadding
            self.tableBorderColor = tableBorderColor
            self.tableBorderWidth = tableBorderWidth
            self.tableHeaderBackground = tableHeaderBackground
            self.tableAlternatingRowColor = tableAlternatingRowColor
        }

        // MARK: - Line Height Resolution

        /// Resolve line height to a concrete multiplier for PDF rendering.
        ///
        /// - Parameters:
        ///   - font: The font being used
        ///   - fontSize: The current font size
        /// - Returns: A multiplier value (e.g., 1.2 means line height = fontSize * 1.2)
        public func resolveLineHeight(for font: PDF.Font, fontSize: PDF.UserSpace.Unit) -> Double {
            switch lineHeight {
            case .normal:
                // CSS "line-height: normal" uses the font's normalLineHeight
                // which is (ascender - descender + leading) / unitsPerEm
                //
                // Per ISO 32000-2 Table 121, Leading is the "spacing between baselines
                // of consecutive lines of text" with a default of 0.
                //
                // For Standard 14 fonts where leading is 0, we fall back to 1.15 multiplier
                // which matches WebKit's typical behavior for Times New Roman and similar fonts.
                let normalHeight = Double(font.metrics.normalLineHeight.value) / 1000.0
                if font.metrics.leading.value == 0 {
                    // No explicit leading - use WebKit-typical 1.15 multiplier
                    let metricsLineHeight = Double(font.metrics.lineHeight.value) / 1000.0
                    let impliedLineGap = 1.15 - metricsLineHeight
                    return metricsLineHeight + max(0, impliedLineGap)
                }
                return normalHeight
            case .multiple(let factor):
                return factor
            case .lengthPercentage(let lp):
                // Convert to multiplier based on font size
                switch lp {
                case .length(let length):
                    // For length values, calculate as multiple of font size
                    let points = PDF.UserSpace.Unit(length, currentSize: fontSize, baseFontSize: defaultFontSize)
                    return points.value / fontSize.value
                case .percentage(let pct):
                    return pct.value / 100.0
                case .calc:
                    // calc() can't be evaluated statically - use normal fallback
                    return Double(font.metrics.normalLineHeight.value) / 1000.0
                }
            case .global:
                // Global values (inherit, initial) - use normal as fallback
                return Double(font.metrics.normalLineHeight.value) / 1000.0
            }
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
