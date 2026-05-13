// CSSStylesheetParserTests.swift
// Phase 1 CSS cascade scaffolding — Commit 3:
// CSS stylesheet parser test budget.
//
// Covers:
//   - Tokenizer: comment strip, identifier, string, hex color, units
//   - Selector parser: type, universal, comma-list, unsupported-don't-crash
//   - Declaration parser: single property, multi-property
//   - @media classification: print, screen, only screen, only print,
//     (min-width: ...), screen and (min-width: ...), comma-lists
//   - Malformed-input safety
//   - Source-order preservation

import Testing

@testable import PDF_HTML_Rendering

@Suite
struct CSSStylesheetParserTests {

    // MARK: - Tokenizer / Comment Handling

    @Test
    func `comments are stripped before parsing rules`() {
        let css = """
        /* leading comment */
        html { line-height: 1.5; /* inline comment */ }
        /* trailing comment */
        """
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        #expect(sheet.rules.count == 1)
        #expect(sheet.rules.first?.selectors == [.type("html")])
        #expect(sheet.rules.first?.declarations.first?.property == "line-height")
        #expect(sheet.rules.first?.declarations.first?.value == "1.5")
    }

    @Test
    func `unterminated comment doesn't crash`() {
        let css = "html { color: red; } /* unterminated"
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        // Should parse the first rule and gracefully bail at the comment.
        #expect(sheet.rules.count == 1)
        #expect(sheet.rules.first?.selectors == [.type("html")])
    }

    // MARK: - Selector Parsing

    @Test
    func `type selectors lowercase`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("H1 { color: red }")
        #expect(sheet.rules.first?.selectors == [.type("h1")])
    }

    @Test
    func `universal selector classified as universal`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("* { box-sizing: border-box }")
        #expect(sheet.rules.first?.selectors == [.universal])
    }

    @Test
    func `comma-separated list parses each element`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(
            "code, pre, tt, kbd, samp { font-family: monospace }"
        )
        let sels = sheet.rules.first?.selectors ?? []
        #expect(sels == [
            .type("code"), .type("pre"), .type("tt"),
            .type("kbd"), .type("samp")
        ])
    }

    @Test
    func `class selector marked unsupported`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(".foo { color: red }")
        if case .unsupported(let raw) = sheet.rules.first?.selectors.first ?? .unsupported("") {
            #expect(raw == ".foo")
        } else {
            Issue.record("Expected .unsupported for class selector")
        }
    }

    @Test
    func `id and attribute and pseudo all unsupported`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(
            "#bar { color: red } [type=button] { color: green } a:hover { color: blue }"
        )
        #expect(sheet.rules.count == 3)
        for rule in sheet.rules {
            if case .unsupported = rule.selectors.first ?? .universal {
                // expected
            } else {
                Issue.record("Expected .unsupported for \(rule.selectors)")
            }
        }
    }

    @Test
    func `pseudo-element ::before unsupported`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("p::before { content: 'x' }")
        if case .unsupported = sheet.rules.first?.selectors.first ?? .universal {
            // expected
        } else {
            Issue.record("Expected .unsupported for pseudo-element")
        }
    }

    @Test
    func `descendant combinator unsupported`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("ul li { padding: 0 }")
        if case .unsupported = sheet.rules.first?.selectors.first ?? .universal {
            // expected
        } else {
            Issue.record("Expected .unsupported for descendant combinator")
        }
    }

    // MARK: - Declaration Parsing

    @Test
    func `single property declaration parses`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("html { line-height: 1.5 }")
        let decls = sheet.rules.first?.declarations ?? []
        #expect(decls.count == 1)
        #expect(decls.first?.property == "line-height")
        #expect(decls.first?.value == "1.5")
    }

    @Test
    func `multi-property declaration block parses`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("""
            body {
                font-family: sans-serif;
                font-size: 14px;
                color: #333;
                line-height: 1.5;
            }
            """)
        let decls = sheet.rules.first?.declarations ?? []
        #expect(decls.count == 4)
        #expect(decls[0].property == "font-family")
        #expect(decls[0].value == "sans-serif")
        #expect(decls[1].property == "font-size")
        #expect(decls[1].value == "14px")
        #expect(decls[2].property == "color")
        #expect(decls[2].value == "#333")
        #expect(decls[3].property == "line-height")
        #expect(decls[3].value == "1.5")
    }

    @Test
    func `value with parens (e.g., rgb) preserves internal commas`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(
            "html { color: rgb(255, 128, 0); background: url('a.png') }"
        )
        let decls = sheet.rules.first?.declarations ?? []
        #expect(decls.count == 2)
        #expect(decls[0].value == "rgb(255, 128, 0)")
        #expect(decls[1].value == "url('a.png')")
    }

    @Test
    func `property names are lowercased`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("html { LINE-HEIGHT: 1.5 }")
        #expect(sheet.rules.first?.declarations.first?.property == "line-height")
    }

    @Test
    func `declaration without semicolon at end of block parses`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("html { line-height: 1.5 }")
        #expect(sheet.rules.first?.declarations.count == 1)
    }

    // MARK: - @media Classification

    @Test
    func `at-media print classifies as printIncludes`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("print")
        #expect(m == .printIncludes)
    }

    @Test
    func `at-media screen classifies as screenOnly`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("screen")
        #expect(m == .screenOnly)
    }

    @Test
    func `at-media only screen classifies as screenOnly`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("only screen")
        #expect(m == .screenOnly)
    }

    @Test
    func `at-media only print classifies as printIncludes`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("only print")
        #expect(m == .printIncludes)
    }

    @Test
    func `at-media min-width feature classifies as bareFeature`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("(min-width: 832px)")
        #expect(m == .bareFeature)
    }

    @Test
    func `at-media screen and feature classifies as screenOnly`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("screen and (min-width: 832px)")
        #expect(m == .screenOnly)
    }

    @Test
    func `at-media only screen and feature classifies as screenOnly`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery(
            "only screen and (max-width: 831px)"
        )
        #expect(m == .screenOnly)
    }

    @Test
    func `at-media all classifies as printIncludes`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("all")
        #expect(m == .printIncludes)
    }

    @Test
    func `at-media tv classifies as other`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("tv")
        #expect(m == .other)
    }

    @Test
    func `at-media comma-list with print classifies as printIncludes`() {
        let m = PDF.HTML.CSS.Stylesheet.Parser.classifyMediaQuery("screen, print")
        #expect(m == .printIncludes)
    }

    @Test
    func `at-media wraps inner rules with mediaContext`() {
        let css = """
            html { line-height: 1.5 }
            @media only screen and (max-width: 831px) {
                html { font-size: 14px }
            }
            @media print {
                body { color: black }
            }
            """
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        #expect(sheet.rules.count == 3)
        #expect(sheet.rules[0].mediaContext == .unconditional)
        #expect(sheet.rules[1].mediaContext == .screenOnly)
        #expect(sheet.rules[2].mediaContext == .printIncludes)
    }

    // MARK: - Other At-Rules (Parse-and-Skip)

    @Test
    func `at-import is silently skipped`() {
        let css = """
            @import url('reset.css');
            html { line-height: 1.5 }
            """
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        #expect(sheet.rules.count == 1)
        #expect(sheet.rules.first?.selectors == [.type("html")])
    }

    @Test
    func `at-keyframes is silently skipped`() {
        let css = """
            @keyframes fade {
                from { opacity: 0 }
                to { opacity: 1 }
            }
            body { color: red }
            """
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        #expect(sheet.rules.count == 1)
        #expect(sheet.rules.first?.selectors == [.type("body")])
    }

    // MARK: - Malformed-Input Safety

    @Test
    func `unterminated rule doesn't crash`() {
        let css = "html { line-height: 1.5"   // missing `}`
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        // Parser exhausts input gracefully; may or may not produce a partial rule.
        // The contract is: NO CRASH.
        _ = sheet
    }

    @Test
    func `garbage input doesn't crash`() {
        let css = "}}}}{{{{;;;;@@@@"
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        _ = sheet
    }

    @Test
    func `empty input produces empty stylesheet`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("")
        #expect(sheet.rules.isEmpty)
    }

    @Test
    func `whitespace-only input produces empty stylesheet`() {
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse("   \n\t  \n  ")
        #expect(sheet.rules.isEmpty)
    }

    // MARK: - Source-Order Preservation

    @Test
    func `rules emitted in source order`() {
        let css = """
            html { line-height: 1.15 }
            html { line-height: 1.5 }
            body { margin: 0 }
            """
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        #expect(sheet.rules.count == 3)
        #expect(sheet.rules[0].declarations.first?.value == "1.15")
        #expect(sheet.rules[1].declarations.first?.value == "1.5")
        #expect(sheet.rules[2].selectors == [.type("body")])
    }

    // MARK: - Real-World normalize.css Excerpt

    @Test
    func `normalize.css-style rules parse without loss`() {
        let css = """
            html { line-height: 1.15; -webkit-text-size-adjust: 100% }
            body { margin: 0 }
            h1 { font-size: 2em; margin: .67em 0 }
            hr { box-sizing: content-box; height: 0; overflow: visible }
            b, strong { font-weight: bolder }
            small { font-size: 80% }
            """
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        #expect(sheet.rules.count == 6)
        #expect(sheet.rules[0].selectors == [.type("html")])
        #expect(sheet.rules[0].declarations.count == 2)
        #expect(sheet.rules[4].selectors == [.type("b"), .type("strong")])
        #expect(sheet.rules[4].declarations.first?.property == "font-weight")
        #expect(sheet.rules[4].declarations.first?.value == "bolder")
        #expect(sheet.rules[5].selectors == [.type("small")])
        #expect(sheet.rules[5].declarations.first?.value == "80%")
    }

    // MARK: - DocumentStyles-Style Cascade

    @Test
    func `DocumentStyles preamble + media-query classification`() {
        // Mirrors HTML.Document.document.swift's DocumentStyles structure.
        let css = """
            html { line-height: 1.15 }
            html { line-height: 1.5 }
            @media only screen and (min-width: 832px) {
                html { font-size: 16px }
            }
            @media only screen and (max-width: 831px) {
                html { font-size: 14px }
            }
            """
        let sheet = PDF.HTML.CSS.Stylesheet.Parser.parse(css)
        #expect(sheet.rules.count == 4)

        // First two: normalize.css line-height then doc override — both
        // unconditional. The cascade-apply step at Commit 4 picks the
        // last source-order rule for any given property at same selector.
        #expect(sheet.rules[0].mediaContext == .unconditional)
        #expect(sheet.rules[1].mediaContext == .unconditional)
        #expect(sheet.rules[0].declarations.first?.value == "1.15")
        #expect(sheet.rules[1].declarations.first?.value == "1.5")

        // Both @media queries are screen-only and skip for PDF.
        #expect(sheet.rules[2].mediaContext == .screenOnly)
        #expect(sheet.rules[3].mediaContext == .screenOnly)
    }
}
