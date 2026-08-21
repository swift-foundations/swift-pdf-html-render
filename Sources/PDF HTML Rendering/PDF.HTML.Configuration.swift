import Dimension_Primitives
import Geometry_Primitives
import Layout_Primitives
import PDF_Rendering
import PDF_Standard

extension PDF.HTML {
    public struct Configuration: Sendable {

        public var paperSize: PDF.UserSpace.Rectangle

        public var margins: PDF.UserSpace.Insets

        public var header: Header

        public var footer: Footer

        public var documentTitle: String?

        public var documentDate: String?

        public var defaultFont: PDF.Font

        public var defaultFontSize: PDF.UserSpace.Size<1>

        public var defaultColor: PDF.Color

        public var lineHeight: LineHeight

        public var paragraphSpacing: Dimension_Primitives.Scale<1, Double>

        public var headingSpacing: Dimension_Primitives.Scale<1, Double>

        public var typography: Typography

        public var indent: Indent

        public var horizontalGapEm: Dimension_Primitives.Scale<1, Double>

        public var table: Table

        public var outline: Outline

        public var link: Link

        public var annotation: Annotation

        public var viewer: Viewer

        public init(
            paperSize: PDF.UserSpace.Rectangle = .a4,
            margins: PDF.UserSpace.Insets = .init(all: 36),
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
    }
}

extension PDF.HTML.Configuration {

    public var mediaBox: PDF.UserSpace.Rectangle {
        paperSize
    }

    public var content: PDF.UserSpace.Rectangle {
        PDF.UserSpace.Rectangle(
            x: .zero + margins.leading,
            y: .zero + margins.top,
            width: paperSize.width - margins.horizontal,
            height: paperSize.height - margins.vertical
        )
    }

    public func resolveLineHeight(for font: PDF.Font, fontSize: PDF.UserSpace.Size<1>) -> Double {
        switch lineHeight {
        case .normal:

            let normalHeight = font.metrics.line.normal.value
            if font.metrics.leading == .zero {
                let metricsLineHeight = font.metrics.line.height.value
                let impliedLineGap = 1.2 - metricsLineHeight
                return metricsLineHeight + max(0, impliedLineGap)
            }
            return normalHeight

        case .multiple(let factor):
            return factor

        case .lengthPercentage(let lp):

            switch lp {
            case .length(let length):

                let points = PDF.UserSpace.Size<1>(
                    length,
                    currentSize: fontSize,
                    baseFontSize: defaultFontSize
                )
                return (points.length / fontSize.length).value

            case .percentage(let pct):
                return pct.value / 100.0

            case .calc:

                return font.metrics.line.normal.value
            }

        case .global:

            return font.metrics.line.normal.value
        }
    }

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
