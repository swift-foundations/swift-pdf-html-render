/// CSS Cascade implementation for style resolution.
///
/// The cascade determines how styles from different sources combine to produce
/// the final computed style for an element. This implementation handles:
/// - User-agent (browser) defaults
/// - Inherited properties from parent elements
/// - Declared inline styles
///
/// Example:
/// ```swift
/// let computed = CSSCascade.computed(
///     base: PDF.ComputedStyle(fontWeight: .bold),  // h1 default
///     inherited: parentStyle,                       // parent's color, font-size, etc.
///     declared: ["color": "red"]                    // inline style
/// )
/// ```
///
/// - SeeAlso: [MDN Web Docs on the Cascade](https://developer.mozilla.org/en-US/docs/Web/CSS/Cascade)
public enum CSSCascade {
    /// CSS properties that inherit from parent by default.
    ///
    /// These properties automatically pass their value to child elements
    /// unless explicitly overridden.
    public static let inheritedProperties: Set<String> = [
        // Text properties
        "color",
        "font-family",
        "font-size",
        "font-weight",
        "font-style",
        "font-variant",
        "line-height",
        "letter-spacing",
        "word-spacing",
        "text-align",
        "text-indent",
        "text-transform",
        "white-space",
        "direction",
        "text-decoration",  // Note: partially inherited in CSS

        // List properties
        "list-style-type",
        "list-style-position",
        "list-style-image",

        // Table properties
        "border-collapse",
        "border-spacing",
        "caption-side",
        "empty-cells",

        // Other inherited properties
        "visibility",
        "cursor",
        "quotes",
    ]

    /// CSS properties that do NOT inherit by default.
    ///
    /// These properties must be explicitly set on each element.
    public static let nonInheritedProperties: Set<String> = [
        // Box model
        "margin",
        "margin-top",
        "margin-right",
        "margin-bottom",
        "margin-left",
        "padding",
        "padding-top",
        "padding-right",
        "padding-bottom",
        "padding-left",
        "border",
        "border-width",
        "border-style",
        "border-color",
        "width",
        "height",
        "min-width",
        "max-width",
        "min-height",
        "max-height",

        // Positioning
        "position",
        "top",
        "right",
        "bottom",
        "left",
        "z-index",
        "float",
        "clear",

        // Display & layout
        "display",
        "overflow",
        "vertical-align",

        // Background
        "background",
        "background-color",
        "background-image",
        "background-position",
        "background-repeat",
        "background-size",
    ]

    /// Compute the final style by applying the CSS cascade.
    ///
    /// This static factory method combines:
    /// 1. Base styles (user-agent defaults for the element type)
    /// 2. Inherited properties from the parent element
    /// 3. Declared inline styles (highest specificity)
    ///
    /// - Parameters:
    ///   - base: User-agent default styles for this element type (e.g., h1 is bold)
    ///   - inherited: The parent element's computed style
    ///   - declared: Inline style declarations as key-value pairs
    /// - Returns: The fully computed style for the element
    public static func computed(
        base: HTML.ComputedStyle,
        inherited: HTML.ComputedStyle,
        declared: [String: String]
    ) -> HTML.ComputedStyle {
        var result = base

        // 1. Apply inherited properties from parent
        for property in inheritedProperties {
            if let parentValue = inherited.value(for: property),
               result.value(for: property) == nil {
                result.set(property, parentValue)
            }
        }

        // 2. Apply declared inline styles (highest specificity)
        for (property, value) in declared {
            result.setFromString(property, value)
        }

        // 3. Resolve relative values
        result.resolveRelativeValues(parentFontSize: inherited.fontSize ?? 12.0)

        return result
    }

    /// Check if a property inherits by default.
    ///
    /// - Parameter property: The CSS property name
    /// - Returns: true if the property inherits, false otherwise
    public static func inherits(_ property: String) -> Bool {
        inheritedProperties.contains(property.lowercased())
    }
}
