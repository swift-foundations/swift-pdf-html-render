// HTML.ComputedStyle.swift

public import PDF_Rendering
public import CSS_Standard

extension HTML {
    /// Computed style values for an HTML element.
    ///
    /// This type collects resolved CSS property values during rendering.
    /// Values are optional - `nil` means "inherit from parent" or "use default".
    public struct ComputedStyle: Sendable {
        // MARK: - Text Properties

        /// Font size in points
        public var fontSize: Double?

        /// Text color
        public var color: PDF.Color?

        /// Font weight (CSS font-weight)
        public var fontWeight: W3C_CSS_Fonts.FontWeight?

        /// Font style (CSS font-style)
        public var fontStyle: W3C_CSS_Fonts.FontStyle?

        /// Font family (CSS font-family)
        public var fontFamily: W3C_CSS_Fonts.FontFamily?

        /// Text alignment
        public var textAlign: W3C_CSS_Text.TextAlign?

        /// Line height multiplier (1.0 = normal)
        public var lineHeight: Double?

        /// Letter spacing in points
        public var letterSpacing: Double?

        /// Text decoration (underline, line-through, etc.)
        public var textDecoration: TextDecoration?

        /// Text transform (uppercase, lowercase, capitalize)
        public var textTransform: TextTransform?

        /// White space handling
        public var whiteSpace: WhiteSpace?

        // MARK: - Box Model

        /// Outer margins
        public var margin: PDF.EdgeInsets?

        /// Inner padding
        public var padding: PDF.EdgeInsets?

        /// Border style
        public var border: BorderStyle?

        /// Element width in points
        public var width: Double?

        /// Element height in points
        public var height: Double?

        /// Maximum width in points
        public var maxWidth: Double?

        /// Minimum width in points
        public var minWidth: Double?

        /// Maximum height in points
        public var maxHeight: Double?

        /// Minimum height in points
        public var minHeight: Double?

        // MARK: - Background

        /// Background color
        public var backgroundColor: PDF.Color?

        // MARK: - Display & Layout

        /// Display type
        public var display: Display?

        /// Vertical alignment
        public var verticalAlign: VerticalAlign?

        /// Opacity (0.0 - 1.0)
        public var opacity: Double?

        // MARK: - List Properties

        /// List style type (disc, decimal, etc.)
        public var listStyleType: ListStyleType?

        /// List style position (inside, outside)
        public var listStylePosition: ListStylePosition?

        // MARK: - Table Properties

        /// Border collapse mode
        public var borderCollapse: BorderCollapse?

        /// Border spacing in points
        public var borderSpacing: Double?

        // MARK: - Link Properties

        /// URL for clickable links (set on <a> elements)
        public var linkURL: String?

        /// Create an empty computed style
        public init(
            // Text properties
            fontSize: Double? = nil,
            color: PDF.Color? = nil,
            fontWeight: FontWeight? = nil,
            fontStyle: FontStyle? = nil,
            fontFamily: FontFamily? = nil,
            textAlign: W3C_CSS_Text.TextAlign? = nil,
            lineHeight: Double? = nil,
            letterSpacing: Double? = nil,
            textDecoration: TextDecoration? = nil,
            textTransform: TextTransform? = nil,
            whiteSpace: WhiteSpace? = nil,
            // Box model
            margin: PDF.EdgeInsets? = nil,
            padding: PDF.EdgeInsets? = nil,
            border: BorderStyle? = nil,
            width: Double? = nil,
            height: Double? = nil,
            maxWidth: Double? = nil,
            minWidth: Double? = nil,
            maxHeight: Double? = nil,
            minHeight: Double? = nil,
            // Background
            backgroundColor: PDF.Color? = nil,
            // Display & layout
            display: Display? = nil,
            verticalAlign: VerticalAlign? = nil,
            opacity: Double? = nil,
            // List properties
            listStyleType: ListStyleType? = nil,
            listStylePosition: ListStylePosition? = nil,
            // Table properties
            borderCollapse: BorderCollapse? = nil,
            borderSpacing: Double? = nil,
            // Link properties
            linkURL: String? = nil
        ) {
            // Text properties
            self.fontSize = fontSize
            self.color = color
            self.fontWeight = fontWeight
            self.fontStyle = fontStyle
            self.fontFamily = fontFamily
            self.textAlign = textAlign
            self.lineHeight = lineHeight
            self.letterSpacing = letterSpacing
            self.textDecoration = textDecoration
            self.textTransform = textTransform
            self.whiteSpace = whiteSpace
            // Box model
            self.margin = margin
            self.padding = padding
            self.border = border
            self.width = width
            self.height = height
            self.maxWidth = maxWidth
            self.minWidth = minWidth
            self.maxHeight = maxHeight
            self.minHeight = minHeight
            // Background
            self.backgroundColor = backgroundColor
            // Display & layout
            self.display = display
            self.verticalAlign = verticalAlign
            self.opacity = opacity
            // List properties
            self.listStyleType = listStyleType
            self.listStylePosition = listStylePosition
            // Table properties
            self.borderCollapse = borderCollapse
            self.borderSpacing = borderSpacing
            // Link properties
            self.linkURL = linkURL
        }

        /// Empty style with no values set
        public static let empty = ComputedStyle()

        /// Merge another style into this one.
        /// Values from `other` override values in `self`.
        public mutating func merge(from other: ComputedStyle) {
            // Text properties
            if let value = other.fontSize { fontSize = value }
            if let value = other.color { color = value }
            if let value = other.fontWeight { fontWeight = value }
            if let value = other.fontStyle { fontStyle = value }
            if let value = other.fontFamily { fontFamily = value }
            if let value = other.textAlign { textAlign = value }
            if let value = other.lineHeight { lineHeight = value }
            if let value = other.letterSpacing { letterSpacing = value }
            if let value = other.textDecoration { textDecoration = value }
            if let value = other.textTransform { textTransform = value }
            if let value = other.whiteSpace { whiteSpace = value }
            // Box model
            if let value = other.margin { margin = value }
            if let value = other.padding { padding = value }
            if let value = other.border { border = value }
            if let value = other.width { width = value }
            if let value = other.height { height = value }
            if let value = other.maxWidth { maxWidth = value }
            if let value = other.minWidth { minWidth = value }
            if let value = other.maxHeight { maxHeight = value }
            if let value = other.minHeight { minHeight = value }
            // Background
            if let value = other.backgroundColor { backgroundColor = value }
            // Display & layout
            if let value = other.display { display = value }
            if let value = other.verticalAlign { verticalAlign = value }
            if let value = other.opacity { opacity = value }
            // List properties
            if let value = other.listStyleType { listStyleType = value }
            if let value = other.listStylePosition { listStylePosition = value }
            // Table properties
            if let value = other.borderCollapse { borderCollapse = value }
            if let value = other.borderSpacing { borderSpacing = value }
            // Link properties
            if let value = other.linkURL { linkURL = value }
        }

        /// Returns a new style with `other` merged in
        public func merging(_ other: ComputedStyle) -> ComputedStyle {
            var result = self
            result.merge(from: other)
            return result
        }

        // MARK: - Dynamic Property Access (for CSS Cascade)

        /// Get a property value by CSS property name
        ///
        /// Returns the value as an Any? for cascade comparison purposes.
        /// Used internally by CSSCascade.
        public func value(for property: String) -> Any? {
            switch property.lowercased() {
            // Text properties
            case "font-size": return fontSize
            case "color": return color
            case "font-weight": return fontWeight
            case "font-style": return fontStyle
            case "font-family": return fontFamily
            case "text-align": return textAlign
            case "line-height": return lineHeight
            case "letter-spacing": return letterSpacing
            case "text-decoration": return textDecoration
            case "text-transform": return textTransform
            case "white-space": return whiteSpace
            // Box model
            case "margin": return margin
            case "padding": return padding
            case "border": return border
            case "width": return width
            case "height": return height
            case "max-width": return maxWidth
            case "min-width": return minWidth
            case "max-height": return maxHeight
            case "min-height": return minHeight
            // Background
            case "background-color": return backgroundColor
            // Display & layout
            case "display": return display
            case "vertical-align": return verticalAlign
            case "opacity": return opacity
            // List properties
            case "list-style-type": return listStyleType
            case "list-style-position": return listStylePosition
            // Table properties
            case "border-collapse": return borderCollapse
            case "border-spacing": return borderSpacing
            default: return nil
            }
        }

        /// Set a property value by CSS property name
        ///
        /// - Parameters:
        ///   - property: The CSS property name
        ///   - value: The value to set (must be the correct type)
        public mutating func set(_ property: String, _ value: Any?) {
            switch property.lowercased() {
            // Text properties
            case "font-size":
                fontSize = value as? Double
            case "color":
                color = value as? PDF.Color
            case "font-weight":
                fontWeight = value as? FontWeight
            case "font-style":
                fontStyle = value as? FontStyle
            case "font-family":
                fontFamily = value as? FontFamily
            case "text-align":
                textAlign = value as? W3C_CSS_Text.TextAlign
            case "line-height":
                lineHeight = value as? Double
            case "letter-spacing":
                letterSpacing = value as? Double
            case "text-decoration":
                textDecoration = value as? TextDecoration
            case "text-transform":
                textTransform = value as? TextTransform
            case "white-space":
                whiteSpace = value as? WhiteSpace
            // Box model
            case "margin":
                margin = value as? PDF.EdgeInsets
            case "padding":
                padding = value as? PDF.EdgeInsets
            case "border":
                border = value as? BorderStyle
            case "width":
                width = value as? Double
            case "height":
                height = value as? Double
            case "max-width":
                maxWidth = value as? Double
            case "min-width":
                minWidth = value as? Double
            case "max-height":
                maxHeight = value as? Double
            case "min-height":
                minHeight = value as? Double
            // Background
            case "background-color":
                backgroundColor = value as? PDF.Color
            // Display & layout
            case "display":
                display = value as? Display
            case "vertical-align":
                verticalAlign = value as? VerticalAlign
            case "opacity":
                opacity = value as? Double
            // List properties
            case "list-style-type":
                listStyleType = value as? ListStyleType
            case "list-style-position":
                listStylePosition = value as? ListStylePosition
            // Table properties
            case "border-collapse":
                borderCollapse = value as? BorderCollapse
            case "border-spacing":
                borderSpacing = value as? Double
            default:
                break
            }
        }

        /// Parse a string value and set the property
        ///
        /// - Parameters:
        ///   - property: The CSS property name
        ///   - stringValue: The CSS value as a string
        public mutating func setFromString(_ property: String, _ stringValue: String) {
            let value = stringValue.lowercased()
            switch property.lowercased() {
            // Text properties
            case "font-size":
                if let parsed = HTML.ElementMapping.parseFontSize(stringValue) {
                    fontSize = parsed
                }
            case "color":
                if let parsed = HTML.ElementMapping.parseColor(stringValue) {
                    color = parsed
                }
            case "font-weight":
                fontWeight = W3C_CSS_Fonts.FontWeight(parsing: value)
            case "font-style":
                fontStyle = W3C_CSS_Fonts.FontStyle(parsing: value)
            case "font-family":
                fontFamily = W3C_CSS_Fonts.FontFamily(parsing: stringValue)
            case "text-align":
                textAlign = HTML.ElementMapping.parseTextAlign(stringValue)
            case "line-height":
                lineHeight = Double(value) ?? HTML.ElementMapping.parseFontSize(stringValue)
            case "letter-spacing":
                letterSpacing = HTML.ElementMapping.parseFontSize(stringValue)
            case "text-decoration":
                textDecoration = TextDecoration(rawValue: value)
            case "text-transform":
                textTransform = TextTransform(rawValue: value)
            case "white-space":
                whiteSpace = WhiteSpace(rawValue: value)
            // Box model
            case "margin":
                if let parsed = HTML.ElementMapping.parseEdgeInsets(stringValue) {
                    margin = parsed
                }
            case "padding":
                if let parsed = HTML.ElementMapping.parseEdgeInsets(stringValue) {
                    padding = parsed
                }
            case "width":
                width = HTML.ElementMapping.parseFontSize(stringValue)
            case "height":
                height = HTML.ElementMapping.parseFontSize(stringValue)
            case "max-width":
                maxWidth = HTML.ElementMapping.parseFontSize(stringValue)
            case "min-width":
                minWidth = HTML.ElementMapping.parseFontSize(stringValue)
            case "max-height":
                maxHeight = HTML.ElementMapping.parseFontSize(stringValue)
            case "min-height":
                minHeight = HTML.ElementMapping.parseFontSize(stringValue)
            // Background
            case "background-color":
                if let parsed = HTML.ElementMapping.parseColor(stringValue) {
                    backgroundColor = parsed
                }
            // Display & layout
            case "display":
                display = Display(rawValue: value)
            case "vertical-align":
                verticalAlign = VerticalAlign(rawValue: value)
            case "opacity":
                opacity = Double(value)
            // List properties
            case "list-style-type":
                listStyleType = ListStyleType(rawValue: value)
            case "list-style-position":
                listStylePosition = ListStylePosition(rawValue: value)
            // Table properties
            case "border-collapse":
                borderCollapse = BorderCollapse(rawValue: value)
            case "border-spacing":
                borderSpacing = HTML.ElementMapping.parseFontSize(stringValue)
            default:
                break
            }
        }

        /// Resolve relative values (em, %) to absolute values
        ///
        /// - Parameter parentFontSize: The parent element's font size for resolving em units
        public mutating func resolveRelativeValues(parentFontSize: Double) {
            // Currently, relative values are resolved during parsing in HTML.ElementMapping.Style
            // This method is a placeholder for future expansion when we use CSS types directly
        }
    }
}


// MARK: - Border Style

extension HTML.ComputedStyle {
    /// Border style for an element
    public struct BorderStyle: Sendable {
        /// Border width in points
        public var width: Double

        /// Border color
        public var color: PDF.Color

        /// Border style type
        public var style: Style

        public init(
            width: Double = 1,
            color: PDF.Color = .black,
            style: Style = .solid
        ) {
            self.width = width
            self.color = color
            self.style = style
        }

        /// Border line style
        public enum Style: Sendable {
            case none
            case solid
            case dashed
            case dotted
        }
    }
}

// MARK: - Text Decoration

extension HTML.ComputedStyle {
    /// Text decoration values
    public enum TextDecoration: String, Sendable {
        case none
        case underline
        case overline
        case lineThrough = "line-through"
    }
}

// MARK: - Text Transform

extension HTML.ComputedStyle {
    /// Text transform values
    public enum TextTransform: String, Sendable {
        case none
        case uppercase
        case lowercase
        case capitalize
    }
}

// MARK: - White Space

extension HTML.ComputedStyle {
    /// White space handling values
    public enum WhiteSpace: String, Sendable {
        case normal
        case nowrap
        case pre
        case preWrap = "pre-wrap"
        case preLine = "pre-line"
    }
}

// MARK: - Display

extension HTML.ComputedStyle {
    /// Display type values
    public enum Display: String, Sendable {
        case block
        case inline
        case inlineBlock = "inline-block"
        case none
        case flex
        case grid
        case table
        case tableRow = "table-row"
        case tableCell = "table-cell"
        case listItem = "list-item"
    }
}

// MARK: - Vertical Align

extension HTML.ComputedStyle {
    /// Vertical alignment values
    public enum VerticalAlign: String, Sendable {
        case baseline
        case top
        case middle
        case bottom
        case textTop = "text-top"
        case textBottom = "text-bottom"
        case sub
        case `super`
    }
}

// MARK: - List Style Type

extension HTML.ComputedStyle {
    /// List style type values
    public enum ListStyleType: String, Sendable {
        case none
        case disc
        case circle
        case square
        case decimal
        case decimalLeadingZero = "decimal-leading-zero"
        case lowerAlpha = "lower-alpha"
        case upperAlpha = "upper-alpha"
        case lowerRoman = "lower-roman"
        case upperRoman = "upper-roman"
    }
}

// MARK: - List Style Position

extension HTML.ComputedStyle {
    /// List style position values
    public enum ListStylePosition: String, Sendable {
        case inside
        case outside
    }
}

// MARK: - Border Collapse

extension HTML.ComputedStyle {
    /// Border collapse values for tables
    public enum BorderCollapse: String, Sendable {
        case separate
        case collapse
    }
}

// MARK: - PDF Font Resolution

extension PDF.Font {
    /// Create a font by applying computed style to a base font
    ///
    /// Example:
    /// ```swift
    /// let style = HTML.ComputedStyle(fontWeight: .bold)
    /// let font = PDF.Font(style, base: .helvetica) // helvetica.bold
    /// ```
    public init(_ style: HTML.ComputedStyle, base: PDF.Font = .helvetica) {
        // Determine base font from fontFamily if specified
        var result: PDF.Font
        if let family = style.fontFamily {
            let pdfFamily = ISO_32000.Font.Family(family)
            result = ISO_32000.Font.find(family: pdfFamily, weight: .regular, style: .normal) ?? base
        } else {
            result = base
        }

        // Apply weight using the .bold computed property
        // This handles family-specific variations correctly
        if let fontWeight = style.fontWeight {
            let pdfWeight = ISO_32000.Font.Weight(fontWeight)
            if pdfWeight == .bold {
                result = result.bold
            }
        }

        // Apply style using the .italic computed property
        // This correctly uses .oblique for Helvetica/Courier and .italic for Times
        if let fontStyle = style.fontStyle {
            switch fontStyle {
            case .italic, .oblique, .obliqueAngle:
                result = result.italic
            default:
                break
            }
        }

        self = result
    }
}
