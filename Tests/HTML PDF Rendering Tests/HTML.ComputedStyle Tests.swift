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
            color: PDF.Color.red,
            fontWeight: .bold,
            fontStyle: .italic,
            textAlign: HTML.ComputedStyle.TextAlignment.center,
            margin: PDF.EdgeInsets(all: 10),
            padding: PDF.EdgeInsets(all: 5),
            border: HTML.ComputedStyle.BorderStyle(width: 2, color: PDF.Color.black),
            backgroundColor: PDF.Color.white
        )

        #expect(style.fontSize == 14)
        #expect(style.color == PDF.Color.red)
        #expect(style.fontWeight == .bold)
        #expect(style.fontStyle == .italic)
        #expect(style.margin?.top == 10)
        #expect(style.padding?.top == 5)
        #expect(style.textAlign == HTML.ComputedStyle.TextAlignment.center)
        #expect(style.backgroundColor == PDF.Color.white)
        #expect(style.border?.width == 2)
    }

    // MARK: - Merging

    @Test
    func `Merge overwrites with new values`() {
        var style = HTML.ComputedStyle(fontSize: 12, color: PDF.Color.black)
        let other = HTML.ComputedStyle(fontSize: 16, fontWeight: .bold)

        style.merge(from: other)

        #expect(style.fontSize == 16)  // Overwritten
        #expect(style.color == PDF.Color.black) // Kept
        #expect(style.fontWeight == .bold) // Added
    }

    @Test
    func `Merge preserves values when other is nil`() {
        var style = HTML.ComputedStyle(fontSize: 12, color: PDF.Color.red)
        let other = HTML.ComputedStyle.empty

        style.merge(from: other)

        #expect(style.fontSize == 12)
        #expect(style.color == PDF.Color.red)
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

//@Suite
//struct `HTML.ComputedStyle.FontWeight Tests` {
//
//    @Test
//    func `Normal and bold values exist`() {
//        let normal = HTML.ComputedStyle.FontWeight.normal
//        let bold = .bold
//
//        #expect(normal != bold)
//    }
//}
//
//// MARK: - Font Style Tests
//
//@Suite
//struct `HTML.ComputedStyle.FontStyle Tests` {
//
//    @Test
//    func `Normal and italic values exist`() {
//        let normal = HTML.ComputedStyle.FontStyle.normal
//        let italic = .italic
//
//        #expect(normal != italic)
//    }
//}

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
        #expect(border.color == PDF.Color.black)
        #expect(border.style == HTML.ComputedStyle.BorderStyle.Style.solid)
    }

    @Test
    func `Creates border with custom values`() {
        let border = HTML.ComputedStyle.BorderStyle(
            width: 3,
            color: PDF.Color.red,
            style: HTML.ComputedStyle.BorderStyle.Style.dashed
        )

        #expect(border.width == 3)
        #expect(border.color == PDF.Color.red)
        #expect(border.style == HTML.ComputedStyle.BorderStyle.Style.dashed)
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
        let font = PDF.Font(style, base: PDF.Font.helvetica)

        #expect(font == PDF.Font.helvetica)
    }

    @Test
    func `Bold style returns bold variant`() {
        let style = HTML.ComputedStyle(fontWeight: .bold)
        let font = PDF.Font(style, base: PDF.Font.helvetica)

        #expect(font == PDF.Font.helvetica.bold)
    }

    @Test
    func `Italic style returns italic variant`() {
        let style = HTML.ComputedStyle(fontStyle: .italic)
        let font = PDF.Font(style, base: PDF.Font.helvetica)

        #expect(font == PDF.Font.helvetica.italic)
    }

    @Test
    func `Bold italic style returns bold italic variant`() {
        let style = HTML.ComputedStyle(fontWeight: .bold, fontStyle: .italic)
        let font = PDF.Font(style, base: PDF.Font.helvetica)

        #expect(font == PDF.Font.helvetica.bold.italic)
    }

    @Test(arguments: [
        (PDF.Font.helvetica, PDF.Font.helvetica.bold),
        (PDF.Font.times, PDF.Font.times.bold),
        (PDF.Font.courier, PDF.Font.courier.bold),
    ])
    func `Bold variant for font families`(base: PDF.Font, expected: PDF.Font) {
        let style = HTML.ComputedStyle(fontWeight: .bold)
        let font = PDF.Font(style, base: base)

        #expect(font == expected)
    }

    @Test(arguments: [
        (PDF.Font.helvetica, PDF.Font.helvetica.italic),
        (PDF.Font.times, PDF.Font.times.italic),
        (PDF.Font.courier, PDF.Font.courier.italic),
    ])
    func `Italic variant for font families`(base: PDF.Font, expected: PDF.Font) {
        let style = HTML.ComputedStyle(fontStyle: .italic)
        let font = PDF.Font(style, base: base)

        #expect(font == expected)
    }

    @Test(arguments: [
        (PDF.Font.helvetica, PDF.Font.helvetica.bold.italic),
        (PDF.Font.times, PDF.Font.times.bold.italic),
        (PDF.Font.courier, PDF.Font.courier.bold.italic),
    ])
    func `Bold italic variant for font families`(base: PDF.Font, expected: PDF.Font) {
        let style = HTML.ComputedStyle(fontWeight: .bold, fontStyle: .italic)
        let font = PDF.Font(style, base: base)

        #expect(font == expected)
    }
}
