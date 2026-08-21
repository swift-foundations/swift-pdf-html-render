import PDF_Rendering
import Standard_Library_Extensions

extension PDF.HTML.CSS.Stylesheet {

    public struct Parser {

        private let input: [Character]
        private var index: Int

        private init(source: String) {

            self.input = Array(source)
            self.index = 0
        }
    }
}

extension PDF.HTML.CSS.Stylesheet.Parser {

    public static func parse(_ source: String) -> PDF.HTML.CSS.Stylesheet {
        var parser = Self(source: source)
        return parser.parseStylesheet()
    }

    private mutating func parseStylesheet() -> PDF.HTML.CSS.Stylesheet {
        var rules: [PDF.HTML.CSS.Rule] = []
        skipNoise()
        while index < input.count {
            if peek() == "@" {
                parseAtRule(into: &rules, currentMediaContext: .unconditional)
            } else if let rule = parseRuleSet(mediaContext: .unconditional) {
                rules.append(rule)
            } else {

                recoverToNextDelimiter()
            }
            skipNoise()
        }
        return PDF.HTML.CSS.Stylesheet(rules: rules)
    }

    private mutating func parseAtRule(
        into rules: inout [PDF.HTML.CSS.Rule],
        currentMediaContext: PDF.HTML.CSS.MediaContext
    ) {

        advance()

        let nameStart = index
        while index < input.count, let c = peek(), c.isLetter || c == "-" {
            advance()
        }
        let atName = String(input[nameStart..<index]).lowercased()

        if atName == "media" {

            let queryStart = index
            while index < input.count, peek() != "{" {
                advance()
            }
            let query = String(
                String(input[queryStart..<index]).trimming(where: \.isWhitespace)
            )
            let classified = Self.classifyMediaQuery(query)

            if peek() == "{" { advance() }

            skipNoise()
            while index < input.count, peek() != "}" {
                if peek() == "@" {

                    parseAtRule(into: &rules, currentMediaContext: classified)
                } else if let rule = parseRuleSet(mediaContext: classified) {
                    rules.append(rule)
                } else {
                    recoverToNextDelimiter()
                }
                skipNoise()
            }

            if peek() == "}" { advance() }
        } else {

            skipAtRuleBody()
        }
    }

    private mutating func skipAtRuleBody() {

        while index < input.count {
            let c = peek()
            if c == ";" {
                advance()
                return
            }
            if c == "{" {
                skipBalancedBraces()
                return
            }
            advance()
        }
    }

    private mutating func skipBalancedBraces() {
        guard peek() == "{" else { return }
        advance()
        var depth = 1
        while index < input.count, depth > 0 {
            let c = peek()
            if c == "{" {
                depth += 1
            } else if c == "}" {
                depth -= 1
            }
            advance()
        }
    }

    private mutating func parseRuleSet(
        mediaContext: PDF.HTML.CSS.MediaContext
    ) -> PDF.HTML.CSS.Rule? {
        let selectorStart = index

        while index < input.count {
            let c = peek()
            if c == "{" { break }
            if c == "}" || c == ";" {

                return nil
            }
            advance()
        }
        guard index < input.count, peek() == "{" else { return nil }

        let selectorList = parseSelectorList(
            String(input[selectorStart..<index])
        )
        advance()

        let declarations = parseDeclarations()

        if peek() == "}" { advance() }

        return PDF.HTML.CSS.Rule(
            selectors: selectorList,
            declarations: declarations,
            mediaContext: mediaContext
        )
    }

    private func parseSelectorList(_ raw: String) -> [PDF.HTML.CSS.Selector] {

        let parts = raw.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        return parts.map { classifySelector(String($0.trimming(where: \.isWhitespace))) }
    }

    private func classifySelector(_ raw: String) -> PDF.HTML.CSS.Selector {
        if raw.isEmpty {
            return .unsupported(raw)
        }
        if raw == "*" {
            return .universal
        }

        for c in raw {
            if ".#[]:>+~&*".contains(c) || c.isWhitespace {
                return .unsupported(raw)
            }
        }

        guard let first = raw.first, first.isLetter else {
            return .unsupported(raw)
        }
        return .type(raw.lowercased())
    }

    private mutating func parseDeclarations() -> [PDF.HTML.CSS.Declaration] {
        var decls: [PDF.HTML.CSS.Declaration] = []
        skipNoise()
        while index < input.count, peek() != "}" {
            if let decl = parseDeclaration() {
                decls.append(decl)
            } else {

                while index < input.count, peek() != ";", peek() != "}" {
                    advance()
                }
                if peek() == ";" { advance() }
            }
            skipNoise()
        }
        return decls
    }

    private mutating func parseDeclaration() -> PDF.HTML.CSS.Declaration? {

        let nameStart = index
        while index < input.count, let c = peek(),
            c.isLetter || c.isNumber || c == "-"
        {
            advance()
        }
        let property = String(input[nameStart..<index]).lowercased()
        guard !property.isEmpty else { return nil }

        skipInlineSpaces()
        guard peek() == ":" else { return nil }
        advance()

        let value = readDeclarationValue()
        if peek() == ";" { advance() }

        return PDF.HTML.CSS.Declaration(
            property: property,
            value: String(value.trimming(where: \.isWhitespace))
        )
    }

    private mutating func readDeclarationValue() -> String {
        let valueStart = index
        var parenDepth = 0
        var inString: Character? = nil
        while index < input.count {
            let c = peek()!
            if let quote = inString {
                if c == quote {
                    inString = nil
                }
            } else if c == "\"" || c == "'" {
                inString = c
            } else if c == "(" {
                parenDepth += 1
            } else if c == ")" {
                if parenDepth > 0 { parenDepth -= 1 }
            } else if parenDepth == 0 {
                if c == ";" || c == "}" { break }
            }
            advance()
        }
        return String(input[valueStart..<index])
    }

    internal static func classifyMediaQuery(_ query: String) -> PDF.HTML.CSS.MediaContext {
        let lowered = String(query.lowercased().trimming(where: \.isWhitespace))
        if lowered.isEmpty { return .bareFeature }

        let parts = lowered.split(separator: ",").map {
            String($0.trimming(where: \.isWhitespace))
        }

        var hasPrint = false
        var hasScreen = false
        var hasAll = false
        var hasBareFeature = false
        var hasOther = false

        for part in parts {
            switch extractMediaType(part) {
            case "print":
                hasPrint = true

            case "screen":
                hasScreen = true

            case "all":
                hasAll = true

            case nil:
                hasBareFeature = true

            case .some(let other):
                _ = other
                hasOther = true
            }
        }

        if hasPrint || hasAll { return .printIncludes }
        if hasScreen && !hasOther { return .screenOnly }
        if hasBareFeature && !hasScreen && !hasOther { return .bareFeature }
        return .other
    }

    private static func extractMediaType(_ part: String) -> String? {
        var tokens = part.split(separator: " ").map(String.init)

        if let first = tokens.first, first == "only" || first == "not" {
            tokens.removeFirst()
        }
        guard let first = tokens.first else { return nil }

        if first.hasPrefix("(") { return nil }
        return first
    }

    private func peek() -> Character? {
        guard index < input.count else { return nil }
        return input[index]
    }

    private mutating func advance() {
        guard index < input.count else { return }
        index += 1
    }

    private mutating func skipNoise() {
        while index < input.count {
            let c = input[index]
            if c.isWhitespace {
                index += 1
            } else if c == "/", index + 1 < input.count, input[index + 1] == "*" {

                index += 2
                while index + 1 < input.count {
                    if input[index] == "*" && input[index + 1] == "/" {
                        index += 2
                        break
                    }
                    index += 1
                }
                if index + 1 >= input.count {

                    index = input.count
                }
            } else {
                break
            }
        }
    }

    private mutating func skipInlineSpaces() {
        while index < input.count {
            let c = input[index]
            if c == " " || c == "\t" {
                index += 1
            } else {
                break
            }
        }
    }

    private mutating func recoverToNextDelimiter() {
        while index < input.count {
            let c = input[index]
            if c == "}" {
                index += 1
                return
            }
            if c == ";" {
                index += 1
                return
            }
            index += 1
        }
    }
}
