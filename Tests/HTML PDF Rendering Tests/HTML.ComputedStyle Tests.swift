// HTML.ComputedStyle Tests.swift

import Testing
@testable import HTML_PDF_Rendering
import PDF_Standard

@Suite
struct `HTML.ComputedStyle Tests` {

    // MARK: - Construction

    @Test
    func `Creates empty style`() {
        let style = HTML.ComputedStyle.empty

        #expect(style.fontSize == nil)
        #expect(style.color == nil)
        #expect(style.fontWeight == nil)
        #expect(style.fontStyle == nil)
        #expect(style.margin == nil)
        #expect(style.padding == nil)
        #expect(style.textAlign == nil)
        #expect(style.backgroundColor == nil)
        #expect(style.border == nil)
    }

    @Test
    func `Creates style with all values`() {
        let style = HTML.ComputedStyle(
            fontSize: 14,
            color: .red,
            fontWeight: .bold,
            fontStyle: .italic,
            margin: PDF.EdgeInsets(all: 10),
            padding: PDF.EdgeInsets(all: 5),
            textAlign: .center,
            backgroundColor: .white,
            border: HTML.ComputedStyle.BorderStyle(width: 2, color: .black)
        )

        #expect(style.fontSize == 14)
        #expect(style.color == .red)
        #expect(style.fontWeight == .bold)
        #expect(style.fontStyle == .italic)
        #expect(style.margin?.top == 10)
        #expect(style.padding?.top == 5)
        #expect(style.textAlign == .center)
        #expect(style.backgroundColor == .white)
        #expect(style.border?.width == 2)
    }

    // MARK: - Merging

    @Test
    func `Merge overwrites with new values`() {
        var style = HTML.ComputedStyle(fontSize: 12, color: .black)
        let other = HTML.ComputedStyle(fontSize: 16, fontWeight: .bold)

        style.merge(from: other)

        #expect(style.fontSize == 16)  // Overwritten
        #expect(style.color == .black) // Kept
        #expect(style.fontWeight == .bold) // Added
    }

    @Test
    func `Merge preserves values when other is nil`() {
        var style = HTML.ComputedStyle(fontSize: 12, color: .red)
        let other = HTML.ComputedStyle.empty

        style.merge(from: other)

        #expect(style.fontSize == 12)
        #expect(style.color == .red)
    }

    @Test
    func `Merging returns new style without mutating original`() {
        let style = HTML.ComputedStyle(fontSize: 12)
        let other = HTML.ComputedStyle(fontWeight: .bold)

        let merged = style.merging(other)

        #expect(style.fontWeight == nil) // Original unchanged
        #expect(merged.fontSize == 12)
        #expect(merged.fontWeight == .bold)
    }
}

// MARK: - Font Weight Tests

@Suite
struct `HTML.ComputedStyle.FontWeight Tests` {

    @Test
    func `Normal and bold values exist`() {
        let normal = HTML.ComputedStyle.FontWeight.normal
        let bold = HTML.ComputedStyle.FontWeight.bold

        #expect(normal != bold)
    }
}

// MARK: - Font Style Tests

@Suite
struct `HTML.ComputedStyle.FontStyle Tests` {

    @Test
    func `Normal and italic values exist`() {
        let normal = HTML.ComputedStyle.FontStyle.normal
        let italic = HTML.ComputedStyle.FontStyle.italic

        #expect(normal != italic)
    }
}

// MARK: - Text Alignment Tests

@Suite
struct `HTML.ComputedStyle.TextAlignment Tests` {

    @Test
    func `All alignment values exist`() {
        let left = HTML.ComputedStyle.TextAlignment.left
        let center = HTML.ComputedStyle.TextAlignment.center
        let right = HTML.ComputedStyle.TextAlignment.right
        let justify = HTML.ComputedStyle.TextAlignment.justify

        #expect(left != center)
        #expect(center != right)
        #expect(right != justify)
    }
}

// MARK: - Border Style Tests

@Suite
struct `HTML.ComputedStyle.BorderStyle Tests` {

    @Test
    func `Creates border with defaults`() {
        let border = HTML.ComputedStyle.BorderStyle()

        #expect(border.width == 1)
        #expect(border.color == .black)
        #expect(border.style == .solid)
    }

    @Test
    func `Creates border with custom values`() {
        let border = HTML.ComputedStyle.BorderStyle(
            width: 3,
            color: .red,
            style: .dashed
        )

        #expect(border.width == 3)
        #expect(border.color == .red)
        #expect(border.style == .dashed)
    }

    @Test
    func `Border style types exist`() {
        let styles: [HTML.ComputedStyle.BorderStyle.Style] = [
            .none, .solid, .dashed, .dotted
        ]
        #expect(styles.count == 4)
    }
}

// MARK: - PDF Font Resolution Tests

@Suite
struct `PDF.Font Resolution Tests` {

    @Test
    func `Empty style returns base font`() {
        let style = HTML.ComputedStyle.empty
        let font = PDF.Font(style, base: .helvetica)

        #expect(font == .helvetica)
    }

    @Test
    func `Bold style returns bold variant`() {
        let style = HTML.ComputedStyle(fontWeight: .bold)
        let font = PDF.Font(style, base: .helvetica)

        #expect(font == .helveticaBold)
    }

    @Test
    func `Italic style returns italic variant`() {
        let style = HTML.ComputedStyle(fontStyle: .italic)
        let font = PDF.Font(style, base: .helvetica)

        #expect(font == .helveticaOblique)
    }

    @Test
    func `Bold italic style returns bold italic variant`() {
        let style = HTML.ComputedStyle(fontWeight: .bold, fontStyle: .italic)
        let font = PDF.Font(style, base: .helvetica)

        #expect(font == .helveticaBoldOblique)
    }

    @Test(arguments: [
        (PDF.Font.helvetica, PDF.Font.helveticaBold),
        (PDF.Font.times, PDF.Font.timesBold),
        (PDF.Font.courier, PDF.Font.courierBold),
    ])
    func `Bold variant for font families`(base: PDF.Font, expected: PDF.Font) {
        let style = HTML.ComputedStyle(fontWeight: .bold)
        let font = PDF.Font(style, base: base)

        #expect(font == expected)
    }

    @Test(arguments: [
        (PDF.Font.helvetica, PDF.Font.helveticaOblique),
        (PDF.Font.times, PDF.Font.timesItalic),
        (PDF.Font.courier, PDF.Font.courierOblique),
    ])
    func `Italic variant for font families`(base: PDF.Font, expected: PDF.Font) {
        let style = HTML.ComputedStyle(fontStyle: .italic)
        let font = PDF.Font(style, base: base)

        #expect(font == expected)
    }

    @Test(arguments: [
        (PDF.Font.helvetica, PDF.Font.helveticaBoldOblique),
        (PDF.Font.times, PDF.Font.timesBoldItalic),
        (PDF.Font.courier, PDF.Font.courierBoldOblique),
    ])
    func `Bold italic variant for font families`(base: PDF.Font, expected: PDF.Font) {
        let style = HTML.ComputedStyle(fontWeight: .bold, fontStyle: .italic)
        let font = PDF.Font(style, base: base)

        #expect(font == expected)
    }
}
