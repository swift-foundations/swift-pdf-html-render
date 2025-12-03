/// CSS specificity value for cascade ordering.
///
/// Specificity determines which CSS rules take precedence when multiple rules
/// could apply to the same element. Higher specificity wins.
///
/// Specificity is calculated as a tuple of (inline, id, class, element):
/// - Inline styles (style="...") have highest precedence
/// - ID selectors (#id) are more specific than class selectors
/// - Class selectors (.class), attribute selectors ([attr]), and pseudo-classes (:hover)
/// - Element selectors (div, p) and pseudo-elements (::before)
///
/// Example:
/// ```swift
/// let inline = CSSSpecificity(inline: 1)           // 1,0,0,0 - highest
/// let id = CSSSpecificity(idCount: 1)              // 0,1,0,0
/// let classes = CSSSpecificity(classCount: 2)      // 0,0,2,0
/// let element = CSSSpecificity(elementCount: 1)    // 0,0,0,1 - lowest
/// ```
///
/// - SeeAlso: [MDN Web Docs on Specificity](https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity)
public struct CSSSpecificity: Comparable, Sendable, Hashable {
    /// Inline style weight (style="" attribute) - highest precedence
    public let inline: Int

    /// ID selector count (#id)
    public let idCount: Int

    /// Class, attribute, and pseudo-class selector count (.class, [attr], :pseudo)
    public let classCount: Int

    /// Element and pseudo-element selector count (div, ::before)
    public let elementCount: Int

    /// Create a specificity value
    ///
    /// - Parameters:
    ///   - inline: 1 if this is an inline style, 0 otherwise
    ///   - idCount: Number of ID selectors
    ///   - classCount: Number of class/attribute/pseudo-class selectors
    ///   - elementCount: Number of element/pseudo-element selectors
    public init(
        inline: Int = 0,
        idCount: Int = 0,
        classCount: Int = 0,
        elementCount: Int = 0
    ) {
        self.inline = inline
        self.idCount = idCount
        self.classCount = classCount
        self.elementCount = elementCount
    }

    // MARK: - Comparable

    public static func < (lhs: CSSSpecificity, rhs: CSSSpecificity) -> Bool {
        // Compare as a tuple - earlier components have higher precedence
        (lhs.inline, lhs.idCount, lhs.classCount, lhs.elementCount) <
        (rhs.inline, rhs.idCount, rhs.classCount, rhs.elementCount)
    }

    // MARK: - Common Values

    /// Zero specificity (universal selector)
    public static let zero = CSSSpecificity()

    /// Inline style specificity (highest)
    public static let inlineStyle = CSSSpecificity(inline: 1)

    /// User-agent default specificity
    public static let userAgent = CSSSpecificity(elementCount: 1)
}

// MARK: - Arithmetic

extension CSSSpecificity {
    /// Combine two specificity values
    public static func + (lhs: CSSSpecificity, rhs: CSSSpecificity) -> CSSSpecificity {
        CSSSpecificity(
            inline: lhs.inline + rhs.inline,
            idCount: lhs.idCount + rhs.idCount,
            classCount: lhs.classCount + rhs.classCount,
            elementCount: lhs.elementCount + rhs.elementCount
        )
    }
}

// MARK: - CustomStringConvertible

extension CSSSpecificity: CustomStringConvertible {
    public var description: String {
        "(\(inline),\(idCount),\(classCount),\(elementCount))"
    }
}
