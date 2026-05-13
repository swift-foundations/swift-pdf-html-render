// StyleBlockInterceptionTests.swift
// Phase 1 CSS cascade scaffolding — Commit 2:
// `<style>` and `<title>` head-element text interception in PDF.HTML.Context.
//
// Validates the contracts:
//   1. `<style>` element text content is captured into `collectedStyleBlocks`
//      (one entry per `<style>`), preserving source order.
//   2. `<style>` element text content is NOT rendered as visible PDF text.
//   3. `<title>` element text content is silently suppressed (Phase 2 will
//      route to ISO_32000.Document.Info.title via a separate field).
//   4. Body text content renders normally (no regression).
//   5. `insideStyleBlock` / `insideTitleBlock` flags clear correctly on pop.

import Foundation
import HTML_Rendering
import Render_Primitives
import Testing

@testable import PDF_HTML_Rendering

@Suite
struct StyleBlockInterceptionTests {

    @Test
    func `style text captures to collectedStyleBlocks; not rendered as visible text`() {
        let doc = HTML.Document {
            HTML.Element.Tag(tag: "div") { HTML.Text("BODY_CONTENT_MARKER") }
        } head: {
            HTML.Element.Tag(tag: "style") { HTML.Text("html { line-height: 1.5 }") }
        }

        let state = Ownership.Mutable(PDF.HTML.prepareContext(configuration: .init()))
        var renderCtx = Render.Context.pdfHTML(state: state)
        renderCtx.render(doc)
        _ = PDF.HTML.finalizeRendering(context: &state.value)

        #expect(state.value.collectedStyleBlocks.count == 1)
        #expect(state.value.collectedStyleBlocks.first?.contains("line-height: 1.5") == true)

        // Flag cleared after pop
        #expect(state.value.insideStyleBlock == false)
        #expect(state.value.currentStyleBlockBuffer.isEmpty)

        // PDF content streams should NOT contain CSS text
        let pageBytes = Array(state.value.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(!pageString.contains("line-height"), "CSS text must not appear in PDF content stream")
        #expect(!pageString.contains("html {"), "CSS rule syntax must not appear in PDF content stream")

        // Body content WAS rendered (sanity)
        #expect(pageString.contains("BODY_CONTENT_MARKER"))
    }

    @Test
    func `title text silently suppressed; body content unaffected`() {
        let doc = HTML.Document {
            HTML.Element.Tag(tag: "div") { HTML.Text("VISIBLE_BODY") }
        } head: {
            HTML.Element.Tag(tag: "title") { HTML.Text("INVISIBLE_TITLE") }
        }

        let state = Ownership.Mutable(PDF.HTML.prepareContext(configuration: .init()))
        var renderCtx = Render.Context.pdfHTML(state: state)
        renderCtx.render(doc)
        _ = PDF.HTML.finalizeRendering(context: &state.value)

        #expect(state.value.insideTitleBlock == false)

        let pageBytes = Array(state.value.pdf.pages.flatMap { $0.contents }.flatMap { $0.data })
        let pageString = String(decoding: pageBytes, as: UTF8.self)
        #expect(!pageString.contains("INVISIBLE_TITLE"), "title text must not appear in PDF content stream")
        #expect(pageString.contains("VISIBLE_BODY"))
    }

    @Test
    func `multiple style blocks preserve source order in collectedStyleBlocks`() {
        let doc = HTML.Document {
            HTML.Element.Tag(tag: "div") { HTML.Text("body") }
        } head: {
            HTML.Element.Tag(tag: "style") { HTML.Text("FIRST_RULE") }
            HTML.Element.Tag(tag: "style") { HTML.Text("SECOND_RULE") }
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
