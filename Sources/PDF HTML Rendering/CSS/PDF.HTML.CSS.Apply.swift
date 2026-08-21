import Dimension_Primitives
import PDF_Rendering
import Standard_Library_Extensions
import W3C_CSS_Fonts
import W3C_CSS_Text
import W3C_CSS_Values

extension PDF.HTML.CSS {

    public enum Apply {}
}

extension PDF.HTML.CSS.Apply {

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

            break
        }
    }

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

    }

    private static func applyFontSize(
        _ value: String,
        to context: inout PDF.HTML.Context,
        configuration: PDF.HTML.Configuration
    ) {
        guard let modifier = parseFontSize(value) else { return }
        modifier.apply(to: &context.pdf, configuration: configuration)
    }

    internal static func parseFontSize(_ value: String) -> W3C_CSS_Fonts.FontSize? {
        let trimmed = String(value.trimming(where: \.isWhitespace))

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

        if trimmed.hasSuffix("%") {
            let raw = String(trimmed.dropLast())
            if let v = Double(raw) {
                return .lengthPercentage(.percentage(W3C_CSS_Values.Percentage(v)))
            }
            return nil
        }

        return parseLengthAsFontSize(trimmed)
    }

    private static func parseLengthAsFontSize(_ s: String) -> W3C_CSS_Fonts.FontSize? {

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
