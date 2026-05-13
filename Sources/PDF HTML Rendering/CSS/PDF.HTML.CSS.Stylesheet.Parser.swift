// PDF.HTML.CSS.Stylesheet.Parser.swift
// Recursive-descent CSS stylesheet parser for Phase 1.
//
// Pattern: follows the institute idiom established by
// `W3C_SVG2.Paths.Path.Parser` — a struct with cursor state
// (input + index) and recursive-descent methods. Single static
// entry point `parse(_:)`.
//
// Phase 1 scope (per Research/css-cascade-architectural-gap-2026-05-13.md):
//   - Tokenizes CSS with comment stripping and whitespace skipping.
//   - Parses rules: selector list + declaration block.
//   - Parses selectors: type, universal, comma-separated lists.
//     Class / ID / attribute / pseudo / combinator selectors are
//     parsed-but-classified `.unsupported` per CSS Selectors §3.1.
//   - Parses declarations into (property, value) string pairs.
//     Value-grammar parsing deferred to Commit 4's per-property
//     modifier dispatchers.
//   - Parses `@media` and classifies into MediaContext.
//   - Other at-rules (`@import`, `@charset`, `@keyframes`, `@supports`,
//     `@page`, etc.) are parsed-and-skipped.
//   - Malformed input does not crash: parser recovers by skipping
//     to the next `;` or `}` delimiter.
//
// Phase 2 (deferred): full selector engine, specificity, !important,
// inheritance propagation, @media viewport-feature evaluation.

import PDF_Rendering

extension PDF.HTML.CSS.Stylesheet {
    /// Parser for CSS stylesheet text content (typically `<style>` block bodies).
    public struct Parser {

        // MARK: - Entry Point

        /// Parse a CSS stylesheet source string.
        ///
        /// - Parameter source: The CSS text content (typically the inner
        ///   text of one `<style>` element).
        /// - Returns: Stylesheet with rules in source order.
        public static func parse(_ source: String) -> PDF.HTML.CSS.Stylesheet {
            var parser = Parser(source: source)
            return parser.parseStylesheet()
        }

        // MARK: - Cursor State

        private let input: [Character]
        private var index: Int

        private init(source: String) {
            // Materialize as Array<Character> for O(1) index advancement.
            self.input = Array(source)
            self.index = 0
        }

        // MARK: - Top-Level

        private mutating func parseStylesheet() -> PDF.HTML.CSS.Stylesheet {
            var rules: [PDF.HTML.CSS.Rule] = []
            skipNoise()
            while index < input.count {
                if peek() == "@" {
                    parseAtRule(into: &rules, currentMediaContext: .unconditional)
                } else if let rule = parseRuleSet(mediaContext: .unconditional) {
                    rules.append(rule)
                } else {
                    // Malformed top-level — recover to next `}` or `;`.
                    recoverToNextDelimiter()
                }
                skipNoise()
            }
            return PDF.HTML.CSS.Stylesheet(rules: rules)
        }

        // MARK: - At-Rules

        private mutating func parseAtRule(
            into rules: inout [PDF.HTML.CSS.Rule],
            currentMediaContext: PDF.HTML.CSS.MediaContext
        ) {
            // Consume '@'
            advance()
            // Read at-rule name.
            let nameStart = index
            while index < input.count, let c = peek(), c.isLetter || c == "-" {
                advance()
            }
            let atName = String(input[nameStart..<index]).lowercased()

            if atName == "media" {
                // Parse query string up to '{'.
                let queryStart = index
                while index < input.count, peek() != "{" {
                    advance()
                }
                let query = String(input[queryStart..<index]).trimmingWhitespace()
                let classified = Self.classifyMediaQuery(query)

                // Consume '{'
                if peek() == "{" { advance() }

                // Parse inner rules until matching '}'.
                skipNoise()
                while index < input.count, peek() != "}" {
                    if peek() == "@" {
                        // Nested at-rule: recurse with classified context as ambient.
                        parseAtRule(into: &rules, currentMediaContext: classified)
                    } else if let rule = parseRuleSet(mediaContext: classified) {
                        rules.append(rule)
                    } else {
                        recoverToNextDelimiter()
                    }
                    skipNoise()
                }
                // Consume closing '}'
                if peek() == "}" { advance() }
            } else {
                // Other at-rules: skip the entire rule including any block.
                // `@import url(...);` ends at `;`; `@keyframes { ... }` ends
                // at matching `}`; `@charset "..."` ends at `;`. Use a
                // unified skip-to-delimiter strategy that handles either.
                skipAtRuleBody()
            }
        }

        private mutating func skipAtRuleBody() {
            // Skip up to next `;` or matching block — whichever comes first.
            // A block is opened by `{` and balanced.
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

        // MARK: - Rule Sets

        private mutating func parseRuleSet(
            mediaContext: PDF.HTML.CSS.MediaContext
        ) -> PDF.HTML.CSS.Rule? {
            let selectorStart = index
            // Read selectors up to '{'.
            while index < input.count {
                let c = peek()
                if c == "{" { break }
                if c == "}" || c == ";" {
                    // Malformed — bail.
                    return nil
                }
                advance()
            }
            guard index < input.count, peek() == "{" else { return nil }

            let selectorList = parseSelectorList(
                String(input[selectorStart..<index])
            )
            advance() // consume '{'

            let declarations = parseDeclarations()

            // Consume '}'
            if peek() == "}" { advance() }

            return PDF.HTML.CSS.Rule(
                selectors: selectorList,
                declarations: declarations,
                mediaContext: mediaContext
            )
        }

        // MARK: - Selectors

        private func parseSelectorList(_ raw: String) -> [PDF.HTML.CSS.Selector] {
            // Split on top-level commas. CSS selectors don't have nested
            // commas at Phase 1 supported levels (universal/type), but
            // attribute selectors `[attr="a,b"]` would; treat them all as
            // .unsupported anyway so naive split suffices.
            let parts = raw.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            return parts.map { classifySelector($0.trimmingWhitespace()) }
        }

        private func classifySelector(_ raw: String) -> PDF.HTML.CSS.Selector {
            if raw.isEmpty {
                return .unsupported(raw)
            }
            if raw == "*" {
                return .universal
            }
            // A pure type selector is an HTML element name: alpha-only,
            // optionally with digits after first letter (e.g., h1, h6).
            // Reject anything containing `.`, `#`, `[`, `]`, `:`, whitespace,
            // `>`, `+`, `~`, `&`, `*`.
            for c in raw {
                if ".#[]:>+~&*".contains(c) || c.isWhitespace {
                    return .unsupported(raw)
                }
            }
            // First character must be alpha (HTML tag names).
            guard let first = raw.first, first.isLetter else {
                return .unsupported(raw)
            }
            return .type(raw.lowercased())
        }

        // MARK: - Declarations

        private mutating func parseDeclarations() -> [PDF.HTML.CSS.Declaration] {
            var decls: [PDF.HTML.CSS.Declaration] = []
            skipNoise()
            while index < input.count, peek() != "}" {
                if let decl = parseDeclaration() {
                    decls.append(decl)
                } else {
                    // Recover to next `;` or `}` within this declaration block.
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
            // Property name: identifier (letters, digits, hyphens).
            let nameStart = index
            while index < input.count, let c = peek(),
                  c.isLetter || c.isNumber || c == "-" {
                advance()
            }
            let property = String(input[nameStart..<index]).lowercased()
            guard !property.isEmpty else { return nil }

            // Expect ':'.
            skipInlineSpaces()
            guard peek() == ":" else { return nil }
            advance()

            // Read value up to ';' or '}', respecting parens and string quotes.
            let value = readDeclarationValue()
            if peek() == ";" { advance() }

            return PDF.HTML.CSS.Declaration(
                property: property,
                value: value.trimmingWhitespace()
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

        // MARK: - @media classification

        /// Classify a media query string against the print/`print`
        /// rendering target.
        ///
        /// Internal-visible so the tests can verify classification logic
        /// without round-tripping through the full parser.
        internal static func classifyMediaQuery(_ query: String) -> PDF.HTML.CSS.MediaContext {
            let lowered = query.lowercased().trimmingWhitespace()
            if lowered.isEmpty { return .bareFeature }

            // Split on top-level commas (media-query-list).
            let parts = lowered.split(separator: ",").map { $0.trimmingWhitespace() }

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

        /// Extract the media type token from a single media-query part.
        /// Returns nil for bare feature queries (e.g., `(min-width: 832px)`).
        ///
        /// Examples:
        ///   "print" → "print"
        ///   "only print" → "print"
        ///   "not screen" → "screen" (Phase 1 ignores `not` negation;
        ///     classified as screen for skip purposes — conservative)
        ///   "screen and (min-width: 832px)" → "screen"
        ///   "(min-width: 832px)" → nil
        private static func extractMediaType(_ part: String) -> String? {
            var tokens = part.split(separator: " ").map(String.init)
            // Strip leading "only" / "not" modifier.
            if let first = tokens.first, first == "only" || first == "not" {
                tokens.removeFirst()
            }
            guard let first = tokens.first else { return nil }
            // Bare feature: starts with '('.
            if first.hasPrefix("(") { return nil }
            return first
        }

        // MARK: - Tokenizer Helpers

        private func peek() -> Character? {
            guard index < input.count else { return nil }
            return input[index]
        }

        private mutating func advance() {
            guard index < input.count else { return }
            index += 1
        }

        /// Skip whitespace and CSS comments (`/* ... */`).
        private mutating func skipNoise() {
            while index < input.count {
                let c = input[index]
                if c.isWhitespace {
                    index += 1
                } else if c == "/", index + 1 < input.count, input[index + 1] == "*" {
                    // Comment: skip until "*/".
                    index += 2
                    while index + 1 < input.count {
                        if input[index] == "*" && input[index + 1] == "/" {
                            index += 2
                            break
                        }
                        index += 1
                    }
                    if index + 1 >= input.count {
                        // Unterminated comment — consume to end.
                        index = input.count
                    }
                } else {
                    break
                }
            }
        }

        /// Skip only horizontal whitespace, not newlines or comments.
        /// Used between identifier and `:` in declaration parsing.
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

        /// Recovery: skip ahead until `}` or `;` at top level.
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
}

// MARK: - String helper

private extension String {
    /// Trim leading/trailing whitespace and newlines.
    func trimmingWhitespace() -> String {
        var start = startIndex
        var end = endIndex
        while start < end, self[start].isWhitespace {
            start = self.index(after: start)
        }
        while start < end, self[self.index(before: end)].isWhitespace {
            end = self.index(before: end)
        }
        return String(self[start..<end])
    }
}

// MARK: - Substring helper

private extension Substring {
    func trimmingWhitespace() -> String {
        String(self).trimmingWhitespace()
    }
}
