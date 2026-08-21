import Byte_Primitives_Standard_Library_Integration
import Foundation
import HTML_Rendering
import Ownership_Mutable_Primitives
import Render_Primitives
import Testing

@testable import PDF_HTML_Rendering

@Suite
struct `Style Block Interception Tests` {

    @Test
    func `style text captures to collectedStyleBlocks; not rendered as visible text`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("BODY_CONTENT_MARKER") }
        } head: {
            HTML.Tag.Element(tag: "style") { HTML.Text("html { line-height: 1.5 }") }
        }

        let state = Ownership.Mutable(PDF.HTML.prepareContext(configuration: .init()))
        var renderCtx = Render.Context.pdfHTML(state: state)
        renderCtx.render(doc)
        _ = PDF.HTML.finalizeRendering(context: &state.value)

        #expect(state.value.collectedStyleBlocks.count == 1)
        #expect(state.value.collectedStyleBlocks.first?.contains("line-height: 1.5") == true)

        #expect(state.value.insideStyleBlock == false)
        #expect(state.value.currentStyleBlockBuffer.isEmpty)

        let pageBytes = Array(state.value.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(
            !pageString.contains("line-height"),
            "CSS text must not appear in PDF content stream"
        )
        #expect(
            !pageString.contains("html {"),
            "CSS rule syntax must not appear in PDF content stream"
        )

        #expect(pageString.contains("BODY_CONTENT_MARKER"))
    }

    @Test
    func `title text silently suppressed; body content unaffected`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("VISIBLE_BODY") }
        } head: {
            HTML.Tag.Element(tag: "title") { HTML.Text("INVISIBLE_TITLE") }
        }

        let state = Ownership.Mutable(PDF.HTML.prepareContext(configuration: .init()))
        var renderCtx = Render.Context.pdfHTML(state: state)
        renderCtx.render(doc)
        _ = PDF.HTML.finalizeRendering(context: &state.value)

        #expect(state.value.insideTitleBlock == false)

        let pageBytes = Array(state.value.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(
            !pageString.contains("INVISIBLE_TITLE"),
            "title text must not appear in PDF content stream"
        )
        #expect(pageString.contains("VISIBLE_BODY"))
    }

    @Test
    func `multiple style blocks preserve source order in collectedStyleBlocks`() {
        let doc = HTML.Document {
            HTML.Tag.Element(tag: "div") { HTML.Text("body") }
        } head: {
            HTML.Tag.Element(tag: "style") { HTML.Text("FIRST_RULE") }
            HTML.Tag.Element(tag: "style") { HTML.Text("SECOND_RULE") }
        }

        let state = Ownership.Mutable(PDF.HTML.prepareContext(configuration: .init()))
        var renderCtx = Render.Context.pdfHTML(state: state)
        renderCtx.render(doc)
        _ = PDF.HTML.finalizeRendering(context: &state.value)

        #expect(state.value.collectedStyleBlocks.count == 2)
        #expect(state.value.collectedStyleBlocks[0] == "FIRST_RULE")
        #expect(state.value.collectedStyleBlocks[1] == "SECOND_RULE")
    }
}
