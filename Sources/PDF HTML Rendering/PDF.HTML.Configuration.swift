// PDF.HTML.Configuration.swift
// Configuration for HTML to PDF transformation

import Dimension_Primitives
import Geometry_Primitives
import ISO_32000
import PDF_Rendering
import PDF_Standard
public import W3C_CSS_Text
public import W3C_CSS_Values

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
        public var paragraphSpacing: Scale<1, Double>

        /// Heading spacing (multiplier of heading size)
        public var headingSpacing: Scale<1, Double>

        // MARK: - Typography Scales

        /// Typography scale settings (subscript, superscript, small text)
        public var typography: Typography

        // MARK: - Block Indentation

        /// Block element indentation settings
        public var indent: Indent

        // MARK: - Spacing

        /// Horizontal gap multiplier in em (default: 0.5, used for list markers)
        public var horizontalGapEm: Scale<1, Double>

        /// Threshold for deferring large headers (default: 0.9, i.e., 90% of page height)
        public var deferredHeaderThreshold: Scale<1, Double>

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
            margins: PDF.UserSpace.EdgeInsets = .init(all: 72),
            header: Header = .init(),
            footer: Footer = .init(),
            documentTitle: String? = nil,
            documentDate: String? = nil,
            defaultFont: PDF.Font = .times,
            defaultFontSize: PDF.UserSpace.Size<1> = 12,
            defaultColor: PDF.Color = .black,
            lineHeight: LineHeight = .normal,
            paragraphSpacing: Scale<1, Double> = 0.5,
            headingSpacing: Scale<1, Double> = 0.8,
            typography: Typography = .init(),
            indent: Indent = .init(),
            horizontalGapEm: Scale<1, Double> = 0.5,
            deferredHeaderThreshold: Scale<1, Double> = 0.9,
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
            self.deferredHeaderThreshold = deferredHeaderThreshold
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
        public func headingMarginEm(for tag: String) -> Scale<1, Double> {
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

// MARK: - Configuration.Header

extension PDF.HTML.Configuration {
    /// Page header configuration.
    public struct Header: Sendable, Equatable {
        /// Height reserved for the header (0 for no header)
        public var height: PDF.UserSpace.Height

        public init(
            height: PDF.UserSpace.Height = .init(0)
        ) {
            self.height = height
        }
    }
}

// MARK: - Configuration.Footer

extension PDF.HTML.Configuration {
    /// Page footer configuration.
    public struct Footer: Sendable, Equatable {
        /// Height reserved for the footer (0 for no footer)
        public var height: PDF.UserSpace.Height

        public init(
            height: PDF.UserSpace.Height = .init(0)
        ) {
            self.height = height
        }
    }
}

// MARK: - Configuration.Typography

extension PDF.HTML.Configuration {
    /// Typography scale settings for subscript, superscript, and small text.
    public struct Typography: Sendable, Equatable {
        /// Scale factor for subscript text (default: 0.83, i.e., 83% of base size)
        public var subscriptScale: Scale<1, Double>

        /// Scale factor for superscript text (default: 0.83)
        public var superscriptScale: Scale<1, Double>

        /// Scale factor for <small> tag text (default: 0.83)
        public var smallScale: Scale<1, Double>

        /// Vertical offset for subscript as em fraction (default: 0.2, negative direction)
        public var subscriptOffset: Scale<1, Double>

        /// Vertical offset for superscript as em fraction (default: 0.4, positive direction)
        public var superscriptOffset: Scale<1, Double>

        public init(
            subscriptScale: Scale<1, Double> = 0.83,
            superscriptScale: Scale<1, Double> = 0.83,
            smallScale: Scale<1, Double> = 0.83,
            subscriptOffset: Scale<1, Double> = 0.2,
            superscriptOffset: Scale<1, Double> = 0.4
        ) {
            self.subscriptScale = subscriptScale
            self.superscriptScale = superscriptScale
            self.smallScale = smallScale
            self.subscriptOffset = subscriptOffset
            self.superscriptOffset = superscriptOffset
        }
    }
}

// MARK: - Configuration.Indent

extension PDF.HTML.Configuration {
    /// Block element indentation settings.
    public struct Indent: Sendable, Equatable {
        /// List indentation (default: 30pt)
        public var list: PDF.UserSpace.Width

        /// Blockquote indentation (default: 30pt)
        public var blockquote: PDF.UserSpace.Width

        /// Figure margin (default: 40pt)
        public var figure: PDF.UserSpace.Width

        public init(
            list: PDF.UserSpace.Width = .init(30),
            blockquote: PDF.UserSpace.Width = .init(30),
            figure: PDF.UserSpace.Width = .init(40)
        ) {
            self.list = list
            self.blockquote = blockquote
            self.figure = figure
        }
    }
}

// MARK: - Configuration.Table

extension PDF.HTML.Configuration {
    /// Table styling configuration.
    public struct Table: Sendable, Equatable {
        /// Cell configuration
        public var cell: Cell

        /// Border styling for table cell edges
        public var border: Border

        /// Background color for table header cells (nil for transparent)
        public var headerBackground: PDF.Color?

        /// Alternating row background color (nil for no alternation)
        public var alternatingRowColor: PDF.Color?

        public init(
            cell: Cell = .init(),
            border: Border = .init(),
            headerBackground: PDF.Color? = .gray(0.9),
            alternatingRowColor: PDF.Color? = nil
        ) {
            self.cell = cell
            self.border = border
            self.headerBackground = headerBackground
            self.alternatingRowColor = alternatingRowColor
        }
    }
}

extension PDF.HTML.Configuration.Table {
    /// Table cell configuration.
    public struct Cell: Sendable, Equatable {
        /// Padding inside table cells
        public var padding: PDF.UserSpace.Size<1>

        public init(
            padding: PDF.UserSpace.Size<1> = 4
        ) {
            self.padding = padding
        }
    }
}

extension PDF.HTML.Configuration.Table {
    /// Table border styling.
    public struct Border: Sendable, Equatable {
        /// Border color
        public var color: PDF.Color

        /// Border width
        public var width: PDF.UserSpace.Size<1>

        public init(
            color: PDF.Color = .gray(0.3),
            width: PDF.UserSpace.Size<1> = 0.5
        ) {
            self.color = color
            self.width = width
        }
    }
}

// MARK: - Configuration.Outline

extension PDF.HTML.Configuration {
    /// Document outline (bookmarks/TOC) configuration.
    public struct Outline: Sendable, Equatable {
        /// Maximum heading level to expand by default in the document outline.
        ///
        /// Controls which outline items are expanded when the PDF is first opened:
        /// - `1`: Only H1 items expanded (default, shows main chapters)
        /// - `2`: H1 and H2 expanded (shows chapters and sections)
        /// - `6`: All levels expanded
        /// - `0`: All levels collapsed
        public var openToLevel: Int

        /// Default RGB color for outline items (nil uses viewer default, typically black).
        ///
        /// Per PDF spec, this is three numbers in the range 0.0 to 1.0,
        /// representing the components in the DeviceRGB colour space.
        public var color: ISO_32000.DeviceRGB?

        /// Default text style flags for outline items.
        ///
        /// - `.italic`: Display outline text in italic
        /// - `.bold`: Display outline text in bold
        public var flags: ISO_32000.Outline.ItemFlags

        public init(
            openToLevel: Int = 1,
            color: ISO_32000.DeviceRGB? = nil,
            flags: ISO_32000.Outline.ItemFlags = []
        ) {
            self.openToLevel = openToLevel
            self.color = color
            self.flags = flags
        }
    }
}

// MARK: - Configuration.Link

extension PDF.HTML.Configuration {
    /// Link annotation configuration.
    public struct Link: Sendable, Equatable {
        /// Visual feedback when clicking links in the PDF.
        ///
        /// - `.none`: No visual feedback
        /// - `.invert`: Invert colors in annotation rectangle (default)
        /// - `.outline`: Invert border of annotation
        /// - `.push`: Display annotation as if pressed
        public var highlightMode: ISO_32000.Annotation.Link.HighlightMode

        public init(
            highlightMode: ISO_32000.Annotation.Link.HighlightMode = .invert
        ) {
            self.highlightMode = highlightMode
        }
    }
}

// MARK: - Configuration.Annotation

extension PDF.HTML.Configuration {
    /// Annotation configuration.
    public struct Annotation: Sendable, Equatable {
        /// Border settings for annotations
        public var border: Border

        public init(
            border: Border = .init()
        ) {
            self.border = border
        }
    }
}

extension PDF.HTML.Configuration.Annotation {
    /// Annotation border configuration.
    public struct Border: Sendable, Equatable {
        /// Border width in points
        public var width: Double

        /// Border style
        public var style: ISO_32000.Border.Style.Kind

        public init(
            width: Double = 1,
            style: ISO_32000.Border.Style.Kind = .solid
        ) {
            self.width = width
            self.style = style
        }
    }
}

// MARK: - Configuration.Viewer

extension PDF.HTML.Configuration {
    /// PDF viewer preferences configuration.
    ///
    /// Controls how the document is presented when opened in a PDF viewer.
    /// All defaults match the ISO 32000 PDF specification.
    public struct Viewer: Sendable, Equatable {
        /// Whether to hide the viewer toolbar when document is active
        public var hideToolbar: Bool

        /// Whether to hide the viewer menu bar when document is active
        public var hideMenubar: Bool

        /// Whether to hide UI elements in the document window
        public var hideWindowUI: Bool

        /// Whether to resize document window to fit first page
        public var fitWindow: Bool

        /// Whether to center document window on screen
        public var centerWindow: Bool

        /// Whether to display document title (vs filename) in window title bar
        public var displayDocTitle: Bool

        /// Page mode after exiting full-screen mode
        public var nonFullScreenPageMode: ISO_32000.NonFullScreenPageMode

        /// Reading direction (affects page positioning in two-up mode)
        public var direction: ISO_32000.Direction

        /// View area and clipping settings
        public var view: View

        /// Print area, clipping, and scaling settings
        public var print: Print

        public init(
            hideToolbar: Bool = false,
            hideMenubar: Bool = false,
            hideWindowUI: Bool = false,
            fitWindow: Bool = false,
            centerWindow: Bool = false,
            displayDocTitle: Bool = false,
            nonFullScreenPageMode: ISO_32000.NonFullScreenPageMode = .useNone,
            direction: ISO_32000.Direction = .leftToRight,
            view: View = .init(),
            print: Print = .init()
        ) {
            self.hideToolbar = hideToolbar
            self.hideMenubar = hideMenubar
            self.hideWindowUI = hideWindowUI
            self.fitWindow = fitWindow
            self.centerWindow = centerWindow
            self.displayDocTitle = displayDocTitle
            self.nonFullScreenPageMode = nonFullScreenPageMode
            self.direction = direction
            self.view = view
            self.print = print
        }
    }
}

extension PDF.HTML.Configuration.Viewer {
    /// View area configuration.
    public struct View: Sendable, Equatable {
        /// Page boundary for display area
        public var area: ISO_32000.Page.Boundary

        /// Page boundary for clipping display
        public var clip: ISO_32000.Page.Boundary

        public init(
            area: ISO_32000.Page.Boundary = .cropBox,
            clip: ISO_32000.Page.Boundary = .cropBox
        ) {
            self.area = area
            self.clip = clip
        }
    }

    /// Print configuration.
    public struct Print: Sendable, Equatable {
        /// Page boundary for print area
        public var area: ISO_32000.Page.Boundary

        /// Page boundary for clipping print output
        public var clip: ISO_32000.Page.Boundary

        /// Default print scaling behavior
        public var scaling: ISO_32000.Print.Scaling

        public init(
            area: ISO_32000.Page.Boundary = .cropBox,
            clip: ISO_32000.Page.Boundary = .cropBox,
            scaling: ISO_32000.Print.Scaling = .appDefault
        ) {
            self.area = area
            self.clip = clip
            self.scaling = scaling
        }
    }
}

// MARK: - Page Info

extension PDF.HTML {
    /// Information about the current page, provided to header/footer builders.
    ///
    /// Used during two-pass rendering to provide accurate page numbers and
    /// section information for running headers and footers.
    public struct PageInfo: Sendable {
        /// Current page number (1-indexed)
        public let pageNumber: Int

        /// Total number of pages in the document
        public let totalPages: Int

        /// Title of the current section (from most recent H1-H3 heading)
        public let sectionTitle: String?

        /// Document title (from configuration)
        public let documentTitle: String?

        /// Document date string (from configuration)
        public let date: String?

        public init(
            pageNumber: Int,
            totalPages: Int,
            sectionTitle: String? = nil,
            documentTitle: String? = nil,
            date: String? = nil
        ) {
            self.pageNumber = pageNumber
            self.totalPages = totalPages
            self.sectionTitle = sectionTitle
            self.documentTitle = documentTitle
            self.date = date
        }
    }
}
