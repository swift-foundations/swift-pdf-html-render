// CSS.BorderShorthandParser.swift
// Minimal parser for the `border-*` shorthand value form
// `<line-width> || <line-style> || <line-color>` per CSS Backgrounds 3 §3.
//
// swift-css's `.css.border(...)` DSL emits inline styles as
// `RawProperty<P>` carrying a serialized string like "1px solid #000000".
// Because the institute's modifier dispatch is type-driven, RawProperty<*>
// does not reach the typed BorderBottom/BorderTop/BorderLeft/BorderRight
// modifiers without a parsing step. This file supplies that parsing layer
// and the conditional RawProperty conformances that hand off to the typed
// modifiers.

public import PDF_Rendering
import PDF_Standard
import Standard_Library_Extensions

/// Marker protocol for per-side border longhand properties. Provides a
/// uniform entry point for the `RawProperty<P>` conditional conformance
/// that hands off to the typed modifier per side.
///
/// swift-css emits per-side borders as `RawProperty<BorderBottom>` etc.,
/// so this protocol lets one conformance dispatch all four sides without
/// triggering Swift's "no more than one conditional conformance" rule.
public protocol BorderSideProperty: W3C_CSS_Shared.Property {
    /// Apply the parsed shorthand parts to the institute context as if a
    /// typed instance of this side's property had been emitted directly.
    static func applyParsedShorthand(
        width: W3C_CSS_Backgrounds.BorderWidth?,
        style: W3C_CSS_Values.LineStyle?,
        color: W3C_CSS_Values.Color?,
        to context: inout PDF.HTML.Context
    )
}

extension W3C_CSS_Backgrounds.BorderBottom: BorderSideProperty {
    public static func applyParsedShorthand(
        width: W3C_CSS_Backgrounds.BorderWidth?,
        style: W3C_CSS_Values.LineStyle?,
        color: W3C_CSS_Values.Color?,
        to context: inout PDF.HTML.Context
    ) {
        W3C_CSS_Backgrounds.BorderBottom(width: width, style: style, color: color)
            .apply(to: &context)
    }
}

extension W3C_CSS_Backgrounds.BorderTop: BorderSideProperty {
    public static func applyParsedShorthand(
        width: W3C_CSS_Backgrounds.BorderWidth?,
        style: W3C_CSS_Values.LineStyle?,
        color: W3C_CSS_Values.Color?,
        to context: inout PDF.HTML.Context
    ) {
        W3C_CSS_Backgrounds.BorderTop(width: width, style: style, color: color)
            .apply(to: &context)
    }
}

extension W3C_CSS_Backgrounds.BorderRight: BorderSideProperty {
    public static func applyParsedShorthand(
        width: W3C_CSS_Backgrounds.BorderWidth?,
        style: W3C_CSS_Values.LineStyle?,
        color: W3C_CSS_Values.Color?,
        to context: inout PDF.HTML.Context
    ) {
        W3C_CSS_Backgrounds.BorderRight(width: width, style: style, color: color)
            .apply(to: &context)
    }
}

extension W3C_CSS_Backgrounds.BorderLeft: BorderSideProperty {
    public static func applyParsedShorthand(
        width: W3C_CSS_Backgrounds.BorderWidth?,
        style: W3C_CSS_Values.LineStyle?,
        color: W3C_CSS_Values.Color?,
        to context: inout PDF.HTML.Context
    ) {
        // BorderLeft.properties uses BorderWidth.Width (keyword) rather than
        // BorderWidth (full) — extract the keyword from the parsed width.
        let widthKeyword: W3C_CSS_Backgrounds.BorderWidth.Width?
        if case .values(let values) = width {
            widthKeyword = values.top
        } else {
            widthKeyword = nil
        }
        Self.properties(
            width: widthKeyword,
            style: style,
            color: color
        ).apply(to: &context)
    }
}

/// Parse a border shorthand value into its (width, style, color) parts.
///
/// Tolerates extra whitespace (single, double, leading, or trailing) since
/// swift-css emits string-interpolation of optional descriptions. Token
/// classification is order-independent: each token is matched against the
/// canonical CSS shapes for width/style/color.
internal func parseBorderShorthand(
    _ value: String
) -> (
    width: W3C_CSS_Backgrounds.BorderWidth?,
    style: W3C_CSS_Values.LineStyle?,
    color: W3C_CSS_Values.Color?
) {
    let tokens = tokenizeBorderShorthand(value)
    var width: W3C_CSS_Backgrounds.BorderWidth?
    var style: W3C_CSS_Values.LineStyle?
    var color: W3C_CSS_Values.Color?

    for token in tokens {
        if style == nil, let s = W3C_CSS_Values.LineStyle(rawValue: token) {
            style = s
            continue
        }
        if width == nil, let w = parseBorderWidthToken(token) {
            width = w
            continue
        }
        if color == nil, let c = parseColorToken(token) {
            color = c
            continue
        }
    }

    return (width: width, style: style, color: color)
}

/// Tokenize on whitespace. Respects parenthesized functional values like
/// `rgb(0, 0, 0)` — the comma-separated args inside `(...)` remain one
/// token.
private func tokenizeBorderShorthand(_ value: String) -> [String] {
    var result: [String] = []
    var current = ""
    var depth = 0
    for ch in value {
        if ch == "(" {
            depth += 1
            current.append(ch)
            continue
        }
        if ch == ")" {
            depth -= 1
            current.append(ch)
            continue
        }
        if depth == 0, ch.isWhitespace {
            if !current.isEmpty {
                result.append(current)
                current = ""
            }
        } else {
            current.append(ch)
        }
    }
    if !current.isEmpty { result.append(current) }
    return result
}

/// Recognize a CSS `<line-width>` token. Accepts `thin`/`medium`/`thick`
/// keywords and `<length>` values (subset: numeric + unit `px`/`em`/`rem`/
/// `pt`/`in`/`cm`/`mm` — matches swift-css's `Length.description` output).
private func parseBorderWidthToken(_ s: String) -> W3C_CSS_Backgrounds.BorderWidth? {
    switch s {
    case "thin", "medium", "thick":
        return parseBorderWidthKeyword(s).map { W3C_CSS_Backgrounds.BorderWidth($0) }

    default:
        if let length = parseLengthToken(s) {
            return W3C_CSS_Backgrounds.BorderWidth(.length(length))
        }
        return nil
    }
}

private func parseBorderWidthKeyword(_ s: String) -> W3C_CSS_Backgrounds.BorderWidth.Width? {
    switch s {
    case "thin": return .thin
    case "medium": return .medium
    case "thick": return .thick
    default: return nil
    }
}

private func parseLengthToken(_ s: String) -> W3C_CSS_Values.Length? {
    let units: [(suffix: String, unit: W3C_CSS_Values.Length.Unit)] = [
        ("px", .px),
        ("rem", .rem),
        ("em", .em),
        ("pt", .pt),
        ("in", .in),
        ("cm", .cm),
        ("mm", .mm),
    ]
    for (suffix, unit) in units {
        if s.hasSuffix(suffix) {
            let numStr = String(s.dropLast(suffix.count))
            if let num = Double(numStr) {
                return .length(num, unit)
            }
        }
    }
    return nil
}

/// Recognize a CSS `<color>` token. Supports `#rgb`/`#rrggbb` hex,
/// `rgb(...)`/`rgba(...)` functional, and named colors (delegated to
/// `W3C_CSS_Values.NamedColor.init(rawValue:)`).
private func parseColorToken(_ s: String) -> W3C_CSS_Values.Color? {
    if s.hasPrefix("#") {
        return .hex(W3C_CSS_Values.HexColor(String(s.dropFirst())))
    }
    if s.hasPrefix("rgb(") || s.hasPrefix("rgba(") {
        let inside = s.drop(while: { $0 != "(" }).dropFirst().dropLast()
        let parts = inside.split(separator: ",").map {
            $0.trimming(where: { $0.isWhitespace && !$0.isNewline })
        }
        if parts.count == 3,
            let r = Int(parts[0]),
            let g = Int(parts[1]),
            let b = Int(parts[2])
        {
            return .rgb(r, g, b)
        }
        if parts.count == 4,
            let r = Int(parts[0]),
            let g = Int(parts[1]),
            let b = Int(parts[2]),
            let a = Double(parts[3])
        {
            return .rgba(r, g, b, a)
        }
        return nil
    }
    if let named = W3C_CSS_Values.NamedColor(rawValue: s) {
        return .named(named)
    }
    return nil
}
