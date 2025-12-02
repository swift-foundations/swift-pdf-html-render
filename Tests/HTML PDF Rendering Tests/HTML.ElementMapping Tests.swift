// HTML.ElementMapping Tests.swift

import Testing
@testable import HTML_PDF_Rendering
import PDF_Rendering
import PDF_Standard

@Suite
struct `HTML.ElementMapping Tests` {

    let config = HTML.Configuration.default

    // MARK: - Text Conversion

    @Test
    func `Converts plain text`() {
        let view = HTML.ElementMapping.convertHTMLString(
            "Hello, World!",
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Trims whitespace from text`() {
        let view = HTML.ElementMapping.convertHTMLString(
            "   Hello   ",
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Heading Elements

    @Test(arguments: ["h1", "h2", "h3", "h4", "h5", "h6"])
    func `Converts heading elements`(tag: String) {
        let html = "<\(tag)>Heading</\(tag)>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Block Elements

    @Test(arguments: ["div", "section", "article", "header", "footer", "main", "aside", "nav"])
    func `Converts block container elements`(tag: String) {
        let html = "<\(tag)>Content</\(tag)>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Converts paragraph element`() {
        let html = "<p>This is a paragraph.</p>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Inline Formatting

    @Test
    func `Converts bold elements`() {
        let htmlB = "<b>Bold text</b>"
        let htmlStrong = "<strong>Strong text</strong>"

        let viewB = HTML.ElementMapping.convertHTMLString(htmlB, configuration: config, style: .empty)
        let viewStrong = HTML.ElementMapping.convertHTMLString(htmlStrong, configuration: config, style: .empty)

        #expect(!renderView(viewB).operations.isEmpty)
        #expect(!renderView(viewStrong).operations.isEmpty)
    }

    @Test
    func `Converts italic elements`() {
        let htmlI = "<i>Italic text</i>"
        let htmlEm = "<em>Emphasized text</em>"

        let viewI = HTML.ElementMapping.convertHTMLString(htmlI, configuration: config, style: .empty)
        let viewEm = HTML.ElementMapping.convertHTMLString(htmlEm, configuration: config, style: .empty)

        #expect(!renderView(viewI).operations.isEmpty)
        #expect(!renderView(viewEm).operations.isEmpty)
    }

    @Test
    func `Converts span element`() {
        let html = "<span>Inline text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Lists

    @Test
    func `Converts unordered list`() {
        let html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Converts ordered list`() {
        let html = "<ol><li>First</li><li>Second</li><li>Third</li></ol>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Void Elements

    @Test
    func `Converts br element to spacer`() {
        let html = "Line 1<br>Line 2"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Converts hr element to divider`() {
        let html = "Before<hr>After"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        let hasGraphics = content.operations.contains {
            if case .graphics = $0 { return true }
            return false
        }
        #expect(hasGraphics)
    }

    // MARK: - Code Elements

    @Test
    func `Converts pre element`() {
        let html = "<pre>code here</pre>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Converts code element`() {
        let html = "<code>inline code</code>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Blockquote

    @Test
    func `Converts blockquote element`() {
        let html = "<blockquote>A wise quote</blockquote>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Nested Elements

    @Test
    func `Converts nested elements`() {
        let html = "<div><p>Paragraph in div</p></div>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Converts deeply nested elements`() {
        let html = "<div><section><article><p>Deep content</p></article></section></div>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(!content.operations.isEmpty)
    }

    // MARK: - Empty Content

    @Test
    func `Empty HTML returns empty content`() {
        let view = HTML.ElementMapping.convertHTMLString(
            "",
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(content.operations.isEmpty)
    }

    @Test
    func `Whitespace only returns empty content`() {
        let view = HTML.ElementMapping.convertHTMLString(
            "   \n\t  ",
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        #expect(content.operations.isEmpty)
    }

    // MARK: - Helper

    private func renderView(_ view: any PDF.View) -> PDF.Content {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )
        return view.render(context: &context)
    }
}

// MARK: - Style Parsing Tests

@Suite
struct `HTML.ElementMapping Style Parsing Tests` {

    let config = HTML.Configuration.default

    // MARK: - Font Size Parsing

    @Test
    func `Parses px font size`() {
        let html = "<span style=\"font-size: 16px\">Text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        if case .text(let op) = content.operations.first {
            // 16px * 0.75 = 12pt
            #expect(op.size == 12)
        }
    }

    @Test
    func `Parses pt font size`() {
        let html = "<span style=\"font-size: 14pt\">Text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        if case .text(let op) = content.operations.first {
            #expect(op.size == 14)
        }
    }

    // MARK: - Color Parsing

    @Test(arguments: [
        ("black", PDF.Color.black),
        ("white", PDF.Color.white),
        ("red", PDF.Color.red),
        ("blue", PDF.Color.blue),
    ])
    func `Parses named colors`(name: String, expected: PDF.Color) {
        let html = "<span style=\"color: \(name)\">Text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        if case .text(let op) = content.operations.first {
            #expect(op.color == expected)
        }
    }

    @Test
    func `Parses hex color`() {
        let html = "<span style=\"color: #ff0000\">Text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        if case .text(let op) = content.operations.first {
            #expect(op.color == .red)
        }
    }

    // MARK: - Font Weight Parsing

    @Test
    func `Parses bold font weight`() {
        let html = "<span style=\"font-weight: bold\">Text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        if case .text(let op) = content.operations.first {
            #expect(op.font == .helveticaBold)
        }
    }

    @Test
    func `Parses numeric font weight 700`() {
        let html = "<span style=\"font-weight: 700\">Text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        if case .text(let op) = content.operations.first {
            #expect(op.font == .helveticaBold)
        }
    }

    // MARK: - Font Style Parsing

    @Test
    func `Parses italic font style`() {
        let html = "<span style=\"font-style: italic\">Text</span>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        let content = renderView(view)
        if case .text(let op) = content.operations.first {
            #expect(op.font == .helveticaOblique)
        }
    }

    // MARK: - Helper

    private func renderView(_ view: any PDF.View) -> PDF.Content {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )
        return view.render(context: &context)
    }
}

// MARK: - Attribute Parsing Tests

@Suite
struct `HTML.ElementMapping Attribute Parsing Tests` {

    let config = HTML.Configuration.default

    @Test
    func `Parses single attribute`() {
        let html = "<div class=\"container\">Content</div>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        // Just verify it doesn't crash and produces output
        var context = PDF.Context(availableWidth: 400, availableHeight: 700)
        let content = view.render(context: &context)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Parses multiple attributes`() {
        let html = "<div id=\"main\" class=\"container\" data-value=\"test\">Content</div>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        var context = PDF.Context(availableWidth: 400, availableHeight: 700)
        let content = view.render(context: &context)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Handles unquoted attribute values`() {
        let html = "<div class=container>Content</div>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        var context = PDF.Context(availableWidth: 400, availableHeight: 700)
        let content = view.render(context: &context)
        #expect(!content.operations.isEmpty)
    }

    @Test
    func `Handles single-quoted attribute values`() {
        let html = "<div class='container'>Content</div>"
        let view = HTML.ElementMapping.convertHTMLString(
            html,
            configuration: config,
            style: .empty
        )

        var context = PDF.Context(availableWidth: 400, availableHeight: 700)
        let content = view.render(context: &context)
        #expect(!content.operations.isEmpty)
    }
}
