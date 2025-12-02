// HTML.ElementMapping.Style.swift

import PDF_Rendering
import PDF_Standard

extension HTML.ElementMapping {

    /// Extract style from inline attributes
    static func styleFromAttributes(_ attributes: [String: String]) -> HTML.ComputedStyle {
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
                if value == "bold" || value == "700" || value == "800" || value == "900" {
                    style.fontWeight = .bold
                }
            case "font-style":
                if value == "italic" || value == "oblique" {
                    style.fontStyle = .italic
                }
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
    static func parseTextAlign(_ value: String) -> HTML.ComputedStyle.TextAlignment? {
        switch value.lowercased() {
        case "left": return .left
        case "center": return .center
        case "right": return .right
        case "justify": return .justify
        default: return nil
        }
    }
}
