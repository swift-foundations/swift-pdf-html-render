// PDF.HTML.Configuration.swift
// Configuration for HTML to PDF transformation

import Dimension_Primitives
import Geometry_Primitives
import Layout_Primitives
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
        public var margins: PDF.UserSpace.Insets

        // MARK: - Headers & Footers

        /// Page header configuration
        public var header: Header

        /// Page footer configuration
        public var footer: Footer

        // MARK: - Document Metadata

        /// Document title (used in headers/footers and PDF metadata)
        public var documentTitle: String?

        /// Document date string (used in headers/footers)
        public var documentDate: String?

        // MARK: - Typography

        /// Default font
        public var defaultFont: PDF.Font

        /// Default font size in points
        public var defaultFontSize: PDF.UserSpace.Size<1>

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
        public var paragraphSpacing: Dimension_Primitives.Scale<1, Double>

        /// Heading spacing (multiplier of heading size)
        public var headingSpacing: Dimension_Primitives.Scale<1, Double>

        // MARK: - Typography Scales

        /// Typography scale settings (subscript, superscript, small text)
        public var typography: Typography

        // MARK: - Block Indentation

        /// Block element indentation settings
        public var indent: Indent

        // MARK: - Spacing

        /// Horizontal gap multiplier in em (default: 0.5, used for list markers)
        public var horizontalGapEm: Dimension_Primitives.Scale<1, Double>

        // MARK: - Table Configuration

        /// Table styling configuration
        public var table: Table

        // MARK: - Outline Configuration

        /// Document outline (bookmarks/TOC) settings
        public var outline: Outline

        // MARK: - Link Configuration

        /// Link annotation settings
        public var link: Link

        // MARK: - Annotation Configuration

        /// Annotation settings
        public var annotation: Annotation

        // MARK: - Viewer Preferences

        /// PDF viewer preferences
        public var viewer: Viewer

        // MARK: - Computed

        /// Media box (same as paper size, for use with PDF.Context)
        public var mediaBox: PDF.UserSpace.Rectangle {
            paperSize
        }

        /// Content area (paper size minus margins) as a Rectangle
        ///
        /// Access `.width` and `.height` for dimensions.
        public var content: PDF.UserSpace.Rectangle {
            PDF.UserSpace.Rectangle(
                x: .zero + margins.leading,
                y: .zero + margins.top,
                width: paperSize.width - margins.horizontal,
                height: paperSize.height - margins.vertical
            )
        }

        // MARK: - Init

        public init(
            paperSize: PDF.UserSpace.Rectangle = .a4,
            margins: PDF.UserSpace.Insets = .init(all: 72),
            header: Header = .init(),
            footer: Footer = .init(),
            documentTitle: String? = nil,
            documentDate: String? = nil,
            defaultFont: PDF.Font = .times,
            defaultFontSize: PDF.UserSpace.Size<1> = 12,
            defaultColor: PDF.Color = .black,
            lineHeight: LineHeight = .normal,
            paragraphSpacing: Dimension_Primitives.Scale<1, Double> = 0.5,
            headingSpacing: Dimension_Primitives.Scale<1, Double> = 0.8,
            typography: Typography = .init(),
            indent: Indent = .init(),
            horizontalGapEm: Dimension_Primitives.Scale<1, Double> = 0.5,
            table: Table = .init(),
            outline: Outline = .init(),
            link: Link = .init(),
            annotation: Annotation = .init(),
            viewer: Viewer = .init()
        ) {
            self.paperSize = paperSize
            self.margins = margins
            self.header = header
            self.footer = footer
            self.documentTitle = documentTitle
            self.documentDate = documentDate
            self.defaultFont = defaultFont
            self.defaultFontSize = defaultFontSize
            self.defaultColor = defaultColor
            self.lineHeight = lineHeight
            self.paragraphSpacing = paragraphSpacing
            self.headingSpacing = headingSpacing
            self.typography = typography
            self.indent = indent
            self.horizontalGapEm = horizontalGapEm
            self.table = table
            self.outline = outline
            self.link = link
            self.annotation = annotation
            self.viewer = viewer
        }

        // MARK: - Line Height Resolution

        /// Resolve line height to a concrete multiplier for PDF rendering.
        ///
        /// - Parameters:
        ///   - font: The font being used
        ///   - fontSize: The current font size
        /// - Returns: A multiplier value (e.g., 1.2 means line height = fontSize * 1.2)
        public func resolveLineHeight(for font: PDF.Font, fontSize: PDF.UserSpace.Size<1>) -> Double {
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
                let normalHeight = font.metrics.line.normal.value
                if font.metrics.leading == .zero {
                    // No explicit leading - use WebKit-typical 1.15 multiplier
                    let metricsLineHeight = font.metrics.line.height.value
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
                    let points = PDF.UserSpace.Size<1>(length, currentSize: fontSize, baseFontSize: defaultFontSize)
                    return (points.length / fontSize.length).value
                case .percentage(let pct):
                    return pct.value / 100.0
                case .calc(_):
                    // calc() can't be evaluated statically - use normal fallback
                    return font.metrics.line.normal.value
                }
            case .global(_):
                // Global values (inherit, initial) - use normal as fallback
                return font.metrics.line.normal.value
            }
        }

        // MARK: - Heading Sizes

        /// Font size for heading level (1-6)
        public func headingSize(level: Int) -> PDF.UserSpace.Size<1> {
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

        /// Margin multiplier (em-based) for heading level (1-6)
        /// Based on WebKit user-agent stylesheet defaults
        public func headingMarginEm(for tag: String) -> Dimension_Primitives.Scale<1, Double> {
            switch tag {
            case "h1": return 0.67
            case "h2": return 0.83
            case "h3": return 1.0
            case "h4": return 1.33
            case "h5": return 1.67
            case "h6": return 2.33
            default: return 1.0
            }
        }
    }
}
