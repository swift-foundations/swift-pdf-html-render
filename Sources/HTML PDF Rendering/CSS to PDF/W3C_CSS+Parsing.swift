// W3C_CSS+Parsing.swift
//
// Extensions to add string parsing initializers to W3C CSS types

import Foundation
import W3C_CSS_Fonts

// MARK: - FontWeight Parsing

extension W3C_CSS_Fonts.FontWeight {
    /// Initialize from a CSS string value
    ///
    /// Parses CSS font-weight values: "normal", "bold", "lighter", "bolder", or numeric (100-900)
    public init?(parsing value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces).lowercased()

        switch trimmed {
        case "normal":
            self = .normal
        case "bold":
            self = .bold
        case "lighter":
            self = .lighter
        case "bolder":
            self = .bolder
        case "inherit", "initial", "unset":
            self = .global(.inherit)
        default:
            // Try to parse as a number
            if let number = Int(trimmed) {
                self = .number(number)
            } else {
                return nil
            }
        }
    }
}

// MARK: - FontStyle Parsing

extension W3C_CSS_Fonts.FontStyle {
    /// Initialize from a CSS string value
    ///
    /// Parses CSS font-style values: "normal", "italic", "oblique"
    public init?(parsing value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces).lowercased()

        switch trimmed {
        case "normal":
            self = .normal
        case "italic":
            self = .italic
        case "oblique":
            self = .oblique
        case "inherit", "initial", "unset":
            self = .global(.inherit)
        default:
            // Check for oblique with angle (e.g., "oblique 20deg")
            if trimmed.hasPrefix("oblique") {
                let rest = trimmed.dropFirst("oblique".count).trimmingCharacters(in: .whitespaces)
                if rest.isEmpty {
                    self = .oblique
                } else if let angle = Self.parseAngle(String(rest)) {
                    self = .obliqueAngle(angle)
                } else {
                    self = .oblique
                }
            } else {
                return nil
            }
        }
    }

    private static func parseAngle(_ value: String) -> Double? {
        let trimmed = value.lowercased()
        if trimmed.hasSuffix("deg") {
            return Double(trimmed.dropLast(3))
        }
        return Double(trimmed)
    }
}

// MARK: - FontFamily Parsing

extension W3C_CSS_Fonts.FontFamily {
    /// Initialize from a CSS string value
    ///
    /// Parses CSS font-family values including generic families and specific font names
    public init?(parsing value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces)

        // Handle global values
        let lowercased = trimmed.lowercased()
        if lowercased == "inherit" || lowercased == "initial" || lowercased == "unset" {
            self = .global(.inherit)
            return
        }

        // Split by comma for multiple families
        let families = trimmed.split(separator: ",").map { part -> Family in
            let cleaned = part.trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                .lowercased()

            // Check for generic families
            switch cleaned {
            case "serif":
                return .generic(.serif)
            case "sans-serif":
                return .generic(.sansSerif)
            case "monospace":
                return .generic(.monospace)
            case "cursive":
                return .generic(.cursive)
            case "fantasy":
                return .generic(.fantasy)
            case "system-ui":
                return .generic(.systemUi)
            case "ui-serif":
                return .generic(.uiSerif)
            case "ui-sans-serif":
                return .generic(.uiSansSerif)
            case "ui-monospace":
                return .generic(.uiMonospace)
            case "ui-rounded":
                return .generic(.uiRounded)
            case "emoji":
                return .generic(.emoji)
            case "math":
                return .generic(.math)
            case "fangsong":
                return .generic(.fangsong)
            default:
                // Treat as specific font name
                return .specific(String(part.trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))))
            }
        }

        if families.isEmpty {
            return nil
        } else if families.count == 1 {
            self = .family(families[0])
        } else {
            self = .families(families)
        }
    }
}
