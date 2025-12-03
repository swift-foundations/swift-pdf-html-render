// HTML.ElementMapping.Style.swift

import HTML_Renderable
import PDF_Rendering
import PDF_Standard
import CSS_Standard

extension HTML.ElementMapping {

    /// Convert CSS properties from HTML.StyleEntry objects to HTML.ComputedStyle.
    ///
    /// This bridges swift-css styles to PDF rendering. Each HTML.StyleEntry contains
    /// a CSS declaration (property:value) that we parse and convert.
    public static func styleFromCSSProperties(_ styles: [HTML.StyleEntry]) -> HTML.ComputedStyle {
        var result = HTML.ComputedStyle.empty

        for style in styles {
            let declarationString = style.declarationString
            // Split declaration into property and value
            guard let colonIndex = declarationString.firstIndex(of: ":") else { continue }
            let property = String(declarationString[..<colonIndex]).trimmingCharacters(in: .whitespaces).lowercased()
            let value = String(declarationString[declarationString.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces).lowercased()

            switch property {
            case "font-size":
                result.fontSize = parseFontSize(value)
            case "color":
                result.color = parseColor(value)
            case "font-weight":
                result.fontWeight = FontWeight(parsing: value)
            case "font-style":
                result.fontStyle = FontStyle(parsing: value)
            case "font-family":
                result.fontFamily = FontFamily(parsing: value)
            case "text-align":
                result.textAlign = parseTextAlign(value)
            case "background-color", "background":
                result.backgroundColor = parseColor(value)
            case "margin":
                result.margin = parseEdgeInsets(value)
            case "margin-top":
                if result.margin == nil { result.margin = PDF.EdgeInsets(all: 0) }
                result.margin?.top = parseLength(value) ?? 0
            case "margin-right":
                if result.margin == nil { result.margin = PDF.EdgeInsets(all: 0) }
                result.margin?.right = parseLength(value) ?? 0
            case "margin-bottom":
                if result.margin == nil { result.margin = PDF.EdgeInsets(all: 0) }
                result.margin?.bottom = parseLength(value) ?? 0
            case "margin-left":
                if result.margin == nil { result.margin = PDF.EdgeInsets(all: 0) }
                result.margin?.left = parseLength(value) ?? 0
            case "padding":
                result.padding = parseEdgeInsets(value)
            case "padding-top":
                if result.padding == nil { result.padding = PDF.EdgeInsets(all: 0) }
                result.padding?.top = parseLength(value) ?? 0
            case "padding-right":
                if result.padding == nil { result.padding = PDF.EdgeInsets(all: 0) }
                result.padding?.right = parseLength(value) ?? 0
            case "padding-bottom":
                if result.padding == nil { result.padding = PDF.EdgeInsets(all: 0) }
                result.padding?.bottom = parseLength(value) ?? 0
            case "padding-left":
                if result.padding == nil { result.padding = PDF.EdgeInsets(all: 0) }
                result.padding?.left = parseLength(value) ?? 0
            default:
                // Unsupported property - skip
                break
            }
        }

        return result
    }

    /// Extract style from inline attributes
    public static func styleFromAttributes(_ attributes: [String: String]) -> HTML.ComputedStyle {
        var style = HTML.ComputedStyle.empty

        guard let styleAttr = attributes["style"] else {
            return style
        }

        // Parse inline style attribute
        let properties = styleAttr.split(separator: ";")
        for prop in properties {
            let parts = prop.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let name = String(parts[0].trimming(where: \.isWhitespace)).lowercased()
            let value = String(parts[1].trimming(where: \.isWhitespace)).lowercased()

            switch name {
            case "font-size":
                style.fontSize = parseFontSize(value)
            case "color":
                style.color = parseColor(value)
            case "font-weight":
                style.fontWeight = FontWeight(parsing: value)
            case "font-style":
                style.fontStyle = FontStyle(parsing: value)
            case "text-align":
                style.textAlign = parseTextAlign(value)
            case "background-color", "background":
                style.backgroundColor = parseColor(value)
            default:
                break
            }
        }

        return style
    }

    /// Parse font size from CSS value
    static func parseFontSize(_ value: String) -> Double? {
        let cleaned = String(value.trimming(where: \.isWhitespace))

        if cleaned.hasSuffix("px") {
            let number = cleaned.dropLast(2)
            return Double(number).map { $0 * 0.75 } // px to pt
        } else if cleaned.hasSuffix("pt") {
            let number = cleaned.dropLast(2)
            return Double(number)
        } else if cleaned.hasSuffix("em") {
            let number = cleaned.dropLast(2)
            return Double(number).map { $0 * 12 } // Assume 12pt base
        } else if cleaned.hasSuffix("%") {
            let number = cleaned.dropLast(1)
            return Double(number).map { $0 / 100 * 12 }
        }

        return Double(cleaned)
    }

    /// Parse color from CSS value
    static func parseColor(_ value: String) -> PDF.Color? {
        let cleaned = String(value.trimming(where: \.isWhitespace)).lowercased()

        // Named colors
        switch cleaned {
        case "black": return .black
        case "white": return .white
        case "red": return .red
        case "green": return .rgb(r: 0, g: 0.5, b: 0)
        case "blue": return .blue
        case "gray", "grey": return .gray50
        default:
            break
        }

        // Hex colors
        if cleaned.hasPrefix("#") {
            return PDF.Color(hex: String(cleaned.dropFirst()))
        }

        // RGB/RGBA
        if cleaned.hasPrefix("rgb") {
            return parseRGBColor(cleaned)
        }

        return nil
    }

    /// Parse RGB/RGBA color (without Foundation)
    static func parseRGBColor(_ value: String) -> PDF.Color? {
        // Extract numbers from rgb(r, g, b) or rgba(r, g, b, a)
        var numbers: [Double] = []
        var currentNumber = ""

        for char in value {
            if char.isNumber || char == "." {
                currentNumber.append(char)
            } else if !currentNumber.isEmpty {
                if let num = Double(currentNumber) {
                    numbers.append(num)
                }
                currentNumber = ""
            }
        }
        // Don't forget the last number
        if !currentNumber.isEmpty, let num = Double(currentNumber) {
            numbers.append(num)
        }

        guard numbers.count >= 3 else { return nil }

        let red = numbers[0] / 255.0
        let green = numbers[1] / 255.0
        let blue = numbers[2] / 255.0

        return .rgb(r: red, g: green, b: blue)
    }

    /// Parse text alignment
    static func parseTextAlign(_ value: String) -> W3C_CSS_Text.TextAlign? {
        switch value.lowercased() {
        case "left": return .left
        case "center": return .center
        case "right": return .right
        case "justify": return .justify
        default: return nil
        }
    }

    /// Parse length value (px, pt, em, etc.) to points
    static func parseLength(_ value: String) -> Double? {
        let cleaned = String(value.trimming(where: \.isWhitespace)).lowercased()

        if cleaned.hasSuffix("px") {
            let number = cleaned.dropLast(2)
            return Double(number).map { $0 * 0.75 } // px to pt
        } else if cleaned.hasSuffix("pt") {
            let number = cleaned.dropLast(2)
            return Double(number)
        } else if cleaned.hasSuffix("em") {
            let number = cleaned.dropLast(2)
            return Double(number).map { $0 * 12 } // Assume 12pt base
        } else if cleaned.hasSuffix("rem") {
            let number = cleaned.dropLast(3)
            return Double(number).map { $0 * 12 } // Assume 12pt base
        } else if cleaned == "0" {
            return 0
        }

        return Double(cleaned)
    }

    /// Parse edge insets from CSS shorthand (e.g., "10px", "10px 20px", "10px 20px 30px 40px")
    static func parseEdgeInsets(_ value: String) -> PDF.EdgeInsets? {
        let parts = value.split(whereSeparator: \.isWhitespace)
            .map { String($0) }

        switch parts.count {
        case 1:
            // All sides same
            guard let all = parseLength(parts[0]) else { return nil }
            return PDF.EdgeInsets(top: all, left: all, bottom: all, right: all)
        case 2:
            // vertical | horizontal
            guard let vertical = parseLength(parts[0]),
                  let horizontal = parseLength(parts[1]) else { return nil }
            return PDF.EdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        case 3:
            // top | horizontal | bottom
            guard let top = parseLength(parts[0]),
                  let horizontal = parseLength(parts[1]),
                  let bottom = parseLength(parts[2]) else { return nil }
            return PDF.EdgeInsets(top: top, left: horizontal, bottom: bottom, right: horizontal)
        case 4:
            // top | right | bottom | left
            guard let top = parseLength(parts[0]),
                  let right = parseLength(parts[1]),
                  let bottom = parseLength(parts[2]),
                  let left = parseLength(parts[3]) else { return nil }
            return PDF.EdgeInsets(top: top, left: left, bottom: bottom, right: right)
        default:
            return nil
        }
    }
}
