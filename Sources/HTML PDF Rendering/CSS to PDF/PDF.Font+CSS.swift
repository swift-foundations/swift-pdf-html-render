// PDF.Font+CSS.swift

import PDF_Standard
import W3C_CSS_Fonts

// MARK: - Font Weight Conversion

extension ISO_32000.Font.Weight {
    /// Initialize from a CSS FontWeight value
    ///
    /// Maps CSS font-weight to PDF font weight:
    /// - normal, lighter, numbers < 600 → regular
    /// - bold, bolder, numbers >= 600 → bold
    ///
    /// Example:
    /// ```swift
    /// let weight = ISO_32000.Font.Weight(.bold)     // .bold
    /// let weight = ISO_32000.Font.Weight(.normal)   // .regular
    /// let weight = ISO_32000.Font.Weight(.number(700)) // .bold
    /// ```
    public init(_ css: W3C_CSS_Fonts.FontWeight) {
        switch css {
        case .bold, .bolder:
            self = .bold
        case .number(let n) where n >= 600:
            self = .bold
        default:
            self = .regular
        }
    }
}

// MARK: - Font Style Conversion

extension ISO_32000.Font.Style {
    /// Initialize from a CSS FontStyle value
    ///
    /// Maps CSS font-style to PDF font style:
    /// - normal → normal
    /// - italic → italic
    /// - oblique (any angle) → oblique
    ///
    /// Example:
    /// ```swift
    /// let style = ISO_32000.Font.Style(.italic)  // .italic
    /// let style = ISO_32000.Font.Style(.oblique) // .oblique
    /// ```
    public init(_ css: W3C_CSS_Fonts.FontStyle) {
        switch css {
        case .italic:
            self = .italic
        case .oblique, .obliqueAngle:
            self = .oblique
        default:
            self = .normal
        }
    }
}

// MARK: - Font Family Conversion

extension ISO_32000.Font.Family {
    /// Initialize from a CSS FontFamily value
    ///
    /// Maps CSS generic font families to PDF Standard 14 font families:
    /// - serif → times
    /// - sans-serif, system-ui → helvetica
    /// - monospace → courier
    ///
    /// For specific font names, attempts to match known families.
    ///
    /// Example:
    /// ```swift
    /// let family = ISO_32000.Font.Family(.sansSerif)  // .helvetica
    /// let family = ISO_32000.Font.Family(.monospace)  // .courier
    /// ```
    public init(_ css: W3C_CSS_Fonts.FontFamily) {
        switch css {
        case .family(let family):
            self = Self.fromFamily(family)
        case .families(let families):
            // Use first family that maps to a PDF font
            for family in families {
                let mapped = Self.fromFamily(family)
                if mapped != .helvetica || family == .generic(.sansSerif) {
                    self = mapped
                    return
                }
            }
            self = .helvetica
        case .global:
            self = .helvetica
        }
    }

    private static func fromFamily(_ family: W3C_CSS_Fonts.FontFamily.Family) -> ISO_32000.Font.Family {
        switch family {
        case .generic(let generic):
            return fromGeneric(generic)
        case .specific(let name):
            return fromSpecificName(name)
        case .multiple(let families):
            for f in families {
                let mapped = fromFamily(f)
                if mapped != .helvetica {
                    return mapped
                }
            }
            return .helvetica
        }
    }

    private static func fromGeneric(_ generic: GenericFamily) -> ISO_32000.Font.Family {
        switch generic {
        case .serif:
            return .times
        case .sansSerif, .systemUi, .uiSansSerif:
            return .helvetica
        case .monospace, .uiMonospace:
            return .courier
        case .cursive, .fantasy:
            return .times  // Fallback for decorative fonts
        case .uiSerif:
            return .times
        case .uiRounded:
            return .helvetica
        case .emoji, .math, .fangsong:
            return .helvetica  // Fallback
        }
    }

    private static func fromSpecificName(_ name: String) -> ISO_32000.Font.Family {
        let lowercased = name.lowercased()

        // Match common font names to PDF families
        if lowercased.contains("times") || lowercased.contains("georgia") ||
           lowercased.contains("serif") && !lowercased.contains("sans") {
            return .times
        }
        if lowercased.contains("courier") || lowercased.contains("mono") ||
           lowercased.contains("consolas") || lowercased.contains("menlo") {
            return .courier
        }
        if lowercased.contains("helvetica") || lowercased.contains("arial") ||
           lowercased.contains("sans") || lowercased.contains("verdana") {
            return .helvetica
        }

        // Default to helvetica for unknown fonts
        return .helvetica
    }
}

// MARK: - Complete Font Conversion

extension ISO_32000.Font {
    /// Initialize from CSS font properties
    ///
    /// Combines CSS font-weight, font-style, and font-family to select
    /// the appropriate PDF Standard 14 font.
    ///
    /// Example:
    /// ```swift
    /// let font = ISO_32000.Font(
    ///     weight: .bold,
    ///     style: .italic,
    ///     family: .serif
    /// )  // Returns Times Bold Italic
    /// ```
    public init(
        weight: W3C_CSS_Fonts.FontWeight = .normal,
        style: W3C_CSS_Fonts.FontStyle = .normal,
        family: W3C_CSS_Fonts.FontFamily = .sansSerif
    ) {
        let pdfWeight = Weight(weight)
        let pdfStyle = Style(style)
        let pdfFamily = Family(family)

        self = Self.find(family: pdfFamily, weight: pdfWeight, style: pdfStyle) ?? .helvetica
    }
}
