// HTML.ComputedStyle.swift

public import PDF_Rendering

extension HTML {
    /// Computed style values for an HTML element.
    ///
    /// This type collects resolved CSS property values during rendering.
    /// Values are optional - `nil` means "inherit from parent" or "use default".
    public struct ComputedStyle: Sendable {
        /// Font size in points
        public var fontSize: Double?

        /// Text color
        public var color: PDF.Color?

        /// Font weight
        public var fontWeight: FontWeight?

        /// Font style
        public var fontStyle: FontStyle?

        /// Outer margins
        public var margin: PDF.EdgeInsets?

        /// Inner padding
        public var padding: PDF.EdgeInsets?

        /// Text alignment
        public var textAlign: TextAlignment?

        /// Background color
        public var backgroundColor: PDF.Color?

        /// Border style
        public var border: BorderStyle?

        /// Create an empty computed style
        public init(
            fontSize: Double? = nil,
            color: PDF.Color? = nil,
            fontWeight: FontWeight? = nil,
            fontStyle: FontStyle? = nil,
            margin: PDF.EdgeInsets? = nil,
            padding: PDF.EdgeInsets? = nil,
            textAlign: TextAlignment? = nil,
            backgroundColor: PDF.Color? = nil,
            border: BorderStyle? = nil
        ) {
            self.fontSize = fontSize
            self.color = color
            self.fontWeight = fontWeight
            self.fontStyle = fontStyle
            self.margin = margin
            self.padding = padding
            self.textAlign = textAlign
            self.backgroundColor = backgroundColor
            self.border = border
        }

        /// Empty style with no values set
        public static let empty = ComputedStyle()

        /// Merge another style into this one.
        /// Values from `other` override values in `self`.
        public mutating func merge(from other: ComputedStyle) {
            if let value = other.fontSize { fontSize = value }
            if let value = other.color { color = value }
            if let value = other.fontWeight { fontWeight = value }
            if let value = other.fontStyle { fontStyle = value }
            if let value = other.margin { margin = value }
            if let value = other.padding { padding = value }
            if let value = other.textAlign { textAlign = value }
            if let value = other.backgroundColor { backgroundColor = value }
            if let value = other.border { border = value }
        }

        /// Returns a new style with `other` merged in
        public func merging(_ other: ComputedStyle) -> ComputedStyle {
            var result = self
            result.merge(from: other)
            return result
        }
    }
}

// MARK: - Font Weight

extension HTML.ComputedStyle {
    /// Font weight values
    public enum FontWeight: Sendable {
        case normal
        case bold
    }
}

// MARK: - Font Style

extension HTML.ComputedStyle {
    /// Font style values
    public enum FontStyle: Sendable {
        case normal
        case italic
    }
}

// MARK: - Text Alignment

extension HTML.ComputedStyle {
    /// Text alignment values
    public enum TextAlignment: Sendable {
        case left
        case center
        case right
        case justify
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

// MARK: - PDF Font Resolution

extension PDF.Font {
    /// Create a font by applying computed style to a base font
    ///
    /// Example:
    /// ```swift
    /// let style = HTML.ComputedStyle(fontWeight: .bold)
    /// let font = PDF.Font(style, base: .helvetica) // helveticaBold
    /// ```
    public init(_ style: HTML.ComputedStyle, base: PDF.Font = .helvetica) {
        switch (style.fontWeight, style.fontStyle) {
        case (.bold, .italic):
            self = base.boldItalicVariant
        case (.bold, _):
            self = base.boldVariant
        case (_, .italic):
            self = base.italicVariant
        default:
            self = base
        }
    }
}

// MARK: - PDF.Font Variants

extension PDF.Font {
    /// Bold variant of this font
    var boldVariant: PDF.Font {
        switch self {
        case .helvetica, .helveticaOblique:
            return .helveticaBold
        case .helveticaBold, .helveticaBoldOblique:
            return self
        case .times, .timesItalic:
            return .timesBold
        case .timesBold, .timesBoldItalic:
            return self
        case .courier, .courierOblique:
            return .courierBold
        case .courierBold, .courierBoldOblique:
            return self
        default:
            return self
        }
    }

    /// Italic variant of this font
    var italicVariant: PDF.Font {
        switch self {
        case .helvetica, .helveticaBold:
            return .helveticaOblique
        case .helveticaOblique, .helveticaBoldOblique:
            return self
        case .times, .timesBold:
            return .timesItalic
        case .timesItalic, .timesBoldItalic:
            return self
        case .courier, .courierBold:
            return .courierOblique
        case .courierOblique, .courierBoldOblique:
            return self
        default:
            return self
        }
    }

    /// Bold italic variant of this font
    var boldItalicVariant: PDF.Font {
        switch self {
        case .helvetica, .helveticaBold, .helveticaOblique, .helveticaBoldOblique:
            return .helveticaBoldOblique
        case .times, .timesBold, .timesItalic, .timesBoldItalic:
            return .timesBoldItalic
        case .courier, .courierBold, .courierOblique, .courierBoldOblique:
            return .courierBoldOblique
        default:
            return self
        }
    }
}
