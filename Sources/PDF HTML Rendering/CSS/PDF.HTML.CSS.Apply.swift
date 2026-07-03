// PDF.HTML.CSS.Apply.swift
// Per-property dispatcher: parse declaration value into a typed CSS modifier
// and apply it via the existing inline-style modifier path.
//
// Phase 1 envelope (closes CC3 line-height + S2 small font-size incidental):
//   - line-height: <number> / <percentage> / normal forms
//   - font-size: <length-percentage> forms (px, em, pt, %)
//   - font-weight: bold / bolder / normal / lighter / <number>
//
// Properties outside the envelope are SILENTLY SKIPPED per CSS Selectors
// §3.1 "unsupported selector matches nothing"-shaped degenerate behavior.
// This is the structurally-correct degenerate behavior, NOT a bandaid.
//
// Phase 1 LIMITATION — computed-value cascade ordering:
// Author rules dispatch AFTER UA-level applyTagStyle. For absolute units
// (pt, px) this is correct: author overwrites UA. For relative units
// (% and em), CSS Values §5.1.2 says percentages on font-size resolve
// against the PARENT element's font-size, NOT the current (UA-modified)
// element. Phase 1 resolves percentages against the current fontSize at
// dispatch time, which is the UA-modified value, producing a multiplicative
// stack instead of the spec-correct parent-resolved value. Phase 2 will
// snapshot the parent's currentSize before applyTagStyle runs, then resolve
// author %/em against that snapshot.
//
// Phase 2 expands the envelope: font-family resolution, color, margin
// shorthand, parent-snapshot computed values for %/em, etc.

import Dimension_Primitives
import PDF_Rendering
import Standard_Library_Extensions
import W3C_CSS_Fonts
import W3C_CSS_Text
import W3C_CSS_Values

extension PDF.HTML.CSS {
    /// Dispatcher mapping `(property, value)` declaration strings to typed
    /// CSS modifiers, applied via the existing `PDF.HTML.Style.Modifier`
    /// path (same machinery as inline `.css.X()` modifiers — author-level
    /// cascade origin, post-UA-applyTagStyle in `_pushElement`).
    public enum Apply {
        /// Apply a single parsed declaration to the rendering context.
        /// Out-of-envelope properties are silently skipped.
        public static func apply(
            declaration: PDF.HTML.CSS.Declaration,
            to context: inout PDF.HTML.Context,
            configuration: PDF.HTML.Configuration
        ) {
            switch declaration.property {
            case "line-height":
                applyLineHeight(declaration.value, to: &context, configuration: configuration)

            case "font-size":
                applyFontSize(declaration.value, to: &context, configuration: configuration)

            case "font-weight":
                applyFontWeight(declaration.value, to: &context, configuration: configuration)

            default:
                // Out-of-envelope. Phase 2 may expand.
                break
            }
        }

        // MARK: - line-height

        private static func applyLineHeight(
            _ value: String,
            to context: inout PDF.HTML.Context,
            configuration: PDF.HTML.Configuration
        ) {
            let trimmed = String(value.trimming(where: \.isWhitespace))
            if trimmed == "normal" {
                W3C_CSS_Text.LineHeight.normal.apply(
                    to: &context.pdf,
                    configuration: configuration
                )
                return
            }
            if trimmed.hasSuffix("%") {
                let raw = String(trimmed.dropLast())
                if let v = Double(raw) {
                    let pct = W3C_CSS_Values.Percentage(v)
                    let modifier = W3C_CSS_Text.LineHeight.lengthPercentage(.percentage(pct))
                    modifier.apply(to: &context.pdf, configuration: configuration)
                }
                return
            }
            if let v = Double(trimmed) {
                W3C_CSS_Text.LineHeight.multiple(v).apply(
                    to: &context.pdf,
                    configuration: configuration
                )
                return
            }
            // <length> (line-height: 24pt etc.) is intentionally deferred
            // by the existing LineHeight modifier (see
            // W3C_CSS_Text.LineHeight+PDF.HTML.Style.Modifier.swift) —
            // Phase 1 inherits that deferral.
        }

        // MARK: - font-size

        private static func applyFontSize(
            _ value: String,
            to context: inout PDF.HTML.Context,
            configuration: PDF.HTML.Configuration
        ) {
            guard let modifier = parseFontSize(value) else { return }
            modifier.apply(to: &context.pdf, configuration: configuration)
        }

        /// Parse a CSS font-size value string into a typed `FontSize`.
        /// Internal so tests can assert parsing without context wiring.
        internal static func parseFontSize(_ value: String) -> W3C_CSS_Fonts.FontSize? {
            let trimmed = String(value.trimming(where: \.isWhitespace))
            // Absolute-size / relative-size keywords
            switch trimmed {
            case "xx-small": return .xxSmall
            case "x-small": return .xSmall
            case "small": return .small
            case "medium": return .medium
            case "large": return .large
            case "x-large": return .xLarge
            case "xx-large": return .xxLarge
            case "xxx-large": return .xxxLarge
            case "smaller": return .smaller
            case "larger": return .larger

            default:
                break
            }
            // Percentage
            if trimmed.hasSuffix("%") {
                let raw = String(trimmed.dropLast())
                if let v = Double(raw) {
                    return .lengthPercentage(.percentage(W3C_CSS_Values.Percentage(v)))
                }
                return nil
            }
            // Length: split number from unit
            return parseLengthAsFontSize(trimmed)
        }

        private static func parseLengthAsFontSize(_ s: String) -> W3C_CSS_Fonts.FontSize? {
            // Find boundary between numeric portion and unit suffix.
            // Numeric portion: optional sign, digits, optional dot+digits.
            var idx = s.startIndex
            if idx < s.endIndex, s[idx] == "+" || s[idx] == "-" {
                idx = s.index(after: idx)
            }
            while idx < s.endIndex, s[idx].isNumber { idx = s.index(after: idx) }
            if idx < s.endIndex, s[idx] == "." {
                idx = s.index(after: idx)
                while idx < s.endIndex, s[idx].isNumber { idx = s.index(after: idx) }
            }
            let numStr = String(s[s.startIndex..<idx])
            let unitStr = String(s[idx..<s.endIndex]).lowercased()
            guard let num = Double(numStr) else { return nil }
            guard let unit = W3C_CSS_Values.Length.Unit(rawValue: unitStr) else { return nil }
            return .lengthPercentage(.length(.length(num, unit)))
        }

        // MARK: - font-weight

        private static func applyFontWeight(
            _ value: String,
            to context: inout PDF.HTML.Context,
            configuration: PDF.HTML.Configuration
        ) {
            let trimmed = String(value.trimming(where: \.isWhitespace))
            let modifier: W3C_CSS_Fonts.FontWeight?
            switch trimmed {
            case "normal": modifier = .normal
            case "bold": modifier = .bold
            case "bolder": modifier = .bolder
            case "lighter": modifier = .lighter

            default:
                if let n = Int(trimmed) {
                    modifier = .number(n)
                } else {
                    modifier = nil
                }
            }
            modifier?.apply(to: &context.pdf, configuration: configuration)
        }
    }
}
