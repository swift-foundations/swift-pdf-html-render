import Byte_Primitives_Standard_Library_Integration
import HTML_Rendering
import Ownership_Mutable_Primitives
import Render_Primitives
import Testing

@testable import PDF_HTML_Rendering

@Suite
struct `CSSCascade Apply Tests` {

    private func render(_ doc: HTML.Document<some HTML.View, some HTML.View>) -> PDF.HTML.Context {
        let state = Ownership.Mutable(
            PDF.HTML.prepareContext(configuration: .init(defaultFontSize: 14))
        )
        var renderCtx = Render.Context.pdfHTML(state: state)
        renderCtx.render(doc)
        _ = PDF.HTML.finalizeRendering(context: &state.value)
        return state.value
    }

    @Test
    func `author CSS absolute font-size overrides UA institute typography.smallScale 0.83`() {

        let doc = HTML.Document {
            HTML.Tag.Element(tag: "small") { HTML.Text("SMALL_TEXT") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("small { font-size: 11.2pt }")
            }
        }

        let ctx = render(doc)

        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)

        let hasAuthor = pageString.contains("11.2 Tf") || pageString.contains("11.20 Tf")
        let hasUA = pageString.contains("11.62 Tf")
        #expect(
            hasAuthor,
            "Author CSS (11.2pt absolute) must win — got bytes: \(pageString.prefix(200))"
        )
        #expect(
            !hasUA,
            "UA institute typography.smallScale (11.62pt) must NOT appear when author CSS overrides"
        )
    }

    @Test
    func `two type-selector rules for same property — second wins`() {

        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("BODY") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("html { line-height: 1.15 } html { line-height: 1.5 }")
            }
        }

        let ctx = render(doc)

        let doc2 = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("BODY") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("div { line-height: 1.15 } div { line-height: 1.5 }")
            }
        }
        let ctx2 = render(doc2)

        #expect(ctx2.parsedStylesheet.rules.count == 2)
        let lastLineHeight = ctx2.parsedStylesheet.rules
            .last(where: { $0.selectors.contains(.type("div")) })?
            .declarations
            .last(where: { $0.property == "line-height" })?
            .value
        #expect(lastLineHeight == "1.5")
        _ = ctx
    }

    @Test
    func `screen-only rule SKIPS for PDF`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("BODY") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text(
                    """
                    @media only screen and (max-width: 831px) {
                        div { font-size: 999px }
                    }
                    """
                )
            }
        }
        let ctx = render(doc)
        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(
            !pageString.contains("999 Tf"),
            "screen-only @media rule MUST be skipped for PDF/print"
        )
    }

    @Test
    func `print rule APPLIES for PDF`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("BODY") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("@media print { div { font-size: 24px } }")
            }
        }
        let ctx = render(doc)
        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)

        #expect(
            pageString.contains("18 Tf") || pageString.contains("18.0 Tf"),
            "print @media rule MUST apply for PDF — got bytes: \(pageString.prefix(200))"
        )
    }

    @Test
    func `bare-feature rule SKIPS in Phase 1`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("BODY") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("@media (min-width: 832px) { div { font-size: 999px } }")
            }
        }
        let ctx = render(doc)
        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(
            !pageString.contains("999 Tf"),
            "bare-feature @media (Phase 1 disposition: no viewport ⇒ no match) MUST skip"
        )
    }

    @Test
    func `selector match is case-insensitive on parsed side and call side`() {

        let doc = HTML.Document {
            HTML.Tag.Element(tag: "DIV") { HTML.Text("X") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("DIV { font-size: 20px }")
            }
        }
        let ctx = render(doc)
        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(
            pageString.contains("15 Tf") || pageString.contains("15.0 Tf"),
            "case-insensitive selector match required (HTML §3.2.2, CSS Syntax §3.1) — got: \(pageString.prefix(200))"
        )
    }

    @Test
    func `property name dispatch is case-insensitive`() {

        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("X") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("div { FONT-SIZE: 20px; Line-Height: 1.5 }")
            }
        }
        let ctx = render(doc)
        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(pageString.contains("15 Tf") || pageString.contains("15.0 Tf"))
    }

    @Test
    func `universal selector matches all elements`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("X") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("* { font-size: 18px }")
            }
        }
        let ctx = render(doc)
        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)

        #expect(
            pageString.contains("13.5 Tf") || pageString.contains("13.50 Tf"),
            "universal selector MUST match (CSS Selectors §3.2). Stream excerpt: \(pageString.prefix(300))"
        )
    }

    @Test
    func `class selector matches nothing in Phase 1`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("X") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text(".my-class { font-size: 999px }")
            }
        }
        let ctx = render(doc)
        let pageBytes = Array(ctx.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(
            !pageString.contains("999 Tf"),
            "class selector MUST match nothing in Phase 1 (CSS Selectors §3.1)"
        )
    }

    @Test
    func `unsupported property silently skipped — doesn't crash`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("X") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("div { -webkit-text-size-adjust: 100%; box-sizing: border-box }")
            }
        }

        let ctx = render(doc)
        #expect(!ctx.pdf.pages.isEmpty)
    }

    @Test
    func `html line-height 1.5 reaches LineHeight modifier (CC3 closure shape)`() {

        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("X") }
        } head: {
            HTML.Tag.Element(tag: "style") {
                HTML.Text("html { line-height: 1.5 }")
            }
        }
        let ctx = render(doc)
        let rules = ctx.parsedStylesheet.rules
        #expect(rules.count == 1)
        #expect(rules.first?.selectors == [.type("html")])
        #expect(rules.first?.mediaContext == .unconditional)
        #expect(rules.first?.declarations.first?.property == "line-height")
        #expect(rules.first?.declarations.first?.value == "1.5")
    }

    @Test
    func `multiple style blocks accumulate rules in source order`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("X") }
        } head: {
            HTML.Tag.Element(tag: "style") { HTML.Text("html { line-height: 1.15 }") }
            HTML.Tag.Element(tag: "style") { HTML.Text("html { line-height: 1.5 }") }
        }
        let ctx = render(doc)
        #expect(ctx.parsedStylesheet.rules.count == 2)
        #expect(ctx.parsedStylesheet.rules[0].declarations.first?.value == "1.15")
        #expect(ctx.parsedStylesheet.rules[1].declarations.first?.value == "1.5")
    }
}
