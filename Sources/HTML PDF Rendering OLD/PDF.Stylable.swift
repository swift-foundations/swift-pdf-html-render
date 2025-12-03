// PDF.Stylable.swift
// Protocol for HTML element types that provide PDF styling information

import PDF_Rendering
import HTML_Renderable

extension PDF {
    /// Style information for rendering HTML elements to PDF.
    ///
    /// This struct captures the visual properties needed to render
    /// an HTML element in PDF format, including font size, weight,
    /// color, and spacing.
    public struct Style: Sendable {
        /// Font size in points, or nil to inherit from parent.
        public var fontSize: Double?

        /// Font weight (normal, bold, etc.), or nil to inherit.
        public var fontWeight: FontWeight?

        /// Text color, or nil to inherit.
        public var color: PDF.Color?

        /// Background color, or nil for transparent.
        public var backgroundColor: PDF.Color?

        /// Whether text should be italic.
        public var italic: Bool?

        /// Whether text should be underlined.
        public var underline: Bool?

        /// Whether text should have strikethrough.
        public var strikethrough: Bool?

        /// Spacing before the element (as a multiplier of font size).
        public var spacingBefore: Double?

        /// Spacing after the element (as a multiplier of font size).
        public var spacingAfter: Double?

        /// Whether this element renders as a block (vs inline).
        public var isBlock: Bool?

        /// Creates a new PDF style.
        public init(
            fontSize: Double? = nil,
            fontWeight: FontWeight? = nil,
            color: PDF.Color? = nil,
            backgroundColor: PDF.Color? = nil,
            italic: Bool? = nil,
            underline: Bool? = nil,
            strikethrough: Bool? = nil,
            spacingBefore: Double? = nil,
            spacingAfter: Double? = nil,
            isBlock: Bool? = nil
        ) {
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.italic = italic
            self.underline = underline
            self.strikethrough = strikethrough
            self.spacingBefore = spacingBefore
            self.spacingAfter = spacingAfter
            self.isBlock = isBlock
        }

        /// An empty style that inherits all values from parent.
        public static let empty = Style()

        /// Merges this style with another, with the other style taking precedence.
        public func merging(_ other: Style) -> Style {
            Style(
                fontSize: other.fontSize ?? self.fontSize,
                fontWeight: other.fontWeight ?? self.fontWeight,
                color: other.color ?? self.color,
                backgroundColor: other.backgroundColor ?? self.backgroundColor,
                italic: other.italic ?? self.italic,
                underline: other.underline ?? self.underline,
                strikethrough: other.strikethrough ?? self.strikethrough,
                spacingBefore: other.spacingBefore ?? self.spacingBefore,
                spacingAfter: other.spacingAfter ?? self.spacingAfter,
                isBlock: other.isBlock ?? self.isBlock
            )
        }

        /// Converts this PDF style to an HTML computed style.
        ///
        /// - Parameter configuration: The HTML configuration for default values.
        /// - Returns: An HTML.ComputedStyle with the values from this PDF style.
        public func toComputedStyle(configuration: HTML.Configuration) -> HTML.ComputedStyle {
            var computedStyle = HTML.ComputedStyle()

            if let fontSize = self.fontSize {
                computedStyle.fontSize = fontSize
            }

            if let fontWeight = self.fontWeight {
                switch fontWeight {
                case .bold, .bolder:
                    computedStyle.fontWeight = .bold
                case .normal, .lighter:
                    computedStyle.fontWeight = .normal
                }
            }

            if let color = self.color {
                computedStyle.color = color
            }

            if let backgroundColor = self.backgroundColor {
                computedStyle.backgroundColor = backgroundColor
            }

            if let italic = self.italic, italic {
                computedStyle.fontStyle = .italic
            }

            if let underline = self.underline {
                computedStyle.textDecoration = underline ? .underline : nil
            }

            if let strikethrough = self.strikethrough, strikethrough {
                computedStyle.textDecoration = .lineThrough
            }

            return computedStyle
        }

        /// Font weight enumeration.
        public enum FontWeight: String, Sendable {
            case normal
            case bold
            case lighter
            case bolder
        }
    }
}

// MARK: - PDF.Stylable Protocol

extension PDF {
    /// Protocol for HTML element types that can provide PDF styling.
    ///
    /// Conforming types provide default PDF style information that is used
    /// when rendering the corresponding HTML element to PDF.
    ///
    /// Example:
    /// ```swift
    /// extension H1: PDF.Stylable {
    ///     public static var pdfStyle: PDF.Style {
    ///         PDF.Style(
    ///             fontSize: 32,
    ///             fontWeight: .bold,
    ///             spacingBefore: 0.5,
    ///             spacingAfter: 0.3,
    ///             isBlock: true
    ///         )
    ///     }
    /// }
    /// ```
    public protocol Stylable {
        /// The default PDF style for this element type.
        ///
        /// This style is merged with inherited styles when rendering.
        static var pdfStyle: PDF.Style { get }
    }
}

// MARK: - Convenience Extensions

extension PDF.Style {
    /// Style for block elements (adds spacing and block rendering).
    public static func block(
        fontSize: Double? = nil,
        fontWeight: FontWeight? = nil,
        spacingBefore: Double = 0,
        spacingAfter: Double = 0
    ) -> PDF.Style {
        PDF.Style(
            fontSize: fontSize,
            fontWeight: fontWeight,
            spacingBefore: spacingBefore,
            spacingAfter: spacingAfter,
            isBlock: true
        )
    }

    /// Style for inline text formatting elements.
    public static func inline(
        fontWeight: FontWeight? = nil,
        italic: Bool? = nil,
        underline: Bool? = nil,
        strikethrough: Bool? = nil,
        color: PDF.Color? = nil,
        backgroundColor: PDF.Color? = nil
    ) -> PDF.Style {
        PDF.Style(
            fontWeight: fontWeight,
            color: color,
            backgroundColor: backgroundColor,
            italic: italic,
            underline: underline,
            strikethrough: strikethrough,
            isBlock: false
        )
    }
}
