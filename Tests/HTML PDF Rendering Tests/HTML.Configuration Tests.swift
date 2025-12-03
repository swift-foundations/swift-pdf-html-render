// HTML.Configuration Tests.swift

import Testing
@testable import HTML_PDF_Rendering
import PDF_Standard

@Suite
struct `HTML.Configuration Tests` {

    // MARK: - Construction

    @Test
    func `Creates configuration with defaults`() {
        let config = HTML.Configuration.default

        #expect(config.paperSize == .a4)
        #expect(config.margins == .standard)
        #expect(config.defaultFont == .helvetica)
        #expect(config.defaultFontSize == 12)
        #expect(config.defaultColor == .black)
        #expect(config.lineHeight == 1.2)
    }

    @Test
    func `Creates configuration with custom values`() {
        let config = HTML.Configuration(
            paperSize: .letter,
            margins: PDF.EdgeInsets(all: 50),
            defaultFont: .timesRoman,
            defaultFontSize: 14,
            defaultColor: .blue,
            cssSupport: .none,
            lineHeight: 1.5
        )

        #expect(config.paperSize == .letter)
        #expect(config.margins.top == 50)
        #expect(config.defaultFont == .timesRoman)
        #expect(config.defaultFontSize == 14)
        #expect(config.defaultColor == .blue)
        #expect(config.lineHeight == 1.5)
    }

    // MARK: - Heading Sizes

    @Test(arguments: [
        (1, 24.0),  // h1 = 2.0x
        (2, 18.0),  // h2 = 1.5x
        (3, 14.04), // h3 = 1.17x
        (4, 12.0),  // h4 = 1.0x
        (5, 9.96),  // h5 = 0.83x
        (6, 8.04),  // h6 = 0.67x
    ])
    func `Calculates heading size for level`(level: Int, expectedSize: Double) {
        let config = HTML.Configuration(defaultFontSize: 12)
        let size = config.headingSize(level: level)

        #expect(abs(size - expectedSize) < 0.01)
    }

    @Test
    func `Heading sizes scale with font size`() {
        let config = HTML.Configuration(defaultFontSize: 16)

        #expect(config.headingSize(level: 1) == 32)  // 16 * 2.0
        #expect(config.headingSize(level: 2) == 24)  // 16 * 1.5
    }

    @Test
    func `Invalid heading level returns default font size`() {
        let config = HTML.Configuration(defaultFontSize: 12)

        #expect(config.headingSize(level: 0) == 12)
        #expect(config.headingSize(level: 7) == 12)
        #expect(config.headingSize(level: -1) == 12)
    }
}

// MARK: - CSS Support Tests

@Suite
struct `HTML.Configuration.CSSSupport Tests` {

    @Test
    func `Basic CSS support is default`() {
        let config = HTML.Configuration.default
        #expect(config.cssSupport == .basic)
    }

    @Test
    func `Can set CSS support to none`() {
        let config = HTML.Configuration(cssSupport: .none)
        #expect(config.cssSupport == .none)
    }
}
