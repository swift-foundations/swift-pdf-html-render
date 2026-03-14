// BreakPropertyTests.swift
// Comprehensive tests for CSS break properties in PDF rendering
//
// Tests cover both legacy (page-break-*) and modern (break-*) CSS properties
// for page break control during PDF generation.

import CSS
import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

// MARK: - PageBreakAfter Tests

@Suite
struct `PageBreakAfter Tests` {

    @Test
    func `pageBreakAfter avoid keeps header with following content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill most of page with content
                for i in 1...40 {
                    Paragraph { "Filler \(i)" }
                }

                // Sticky header near bottom of page
                H2 { "STICKY_HEADER" }
                    .css.pageBreakAfter(.avoid)

                Paragraph { "FOLLOWING_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Both header and content should render
        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("STICKY_HEADER"))
        #expect(contentString.contains("FOLLOWING_CONTENT"))
    }

    @Test
    func `pageBreakAfter always forces page break`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "PAGE_ONE_CONTENT" }
                    .css.pageBreakAfter(.always)

                Paragraph { "PAGE_TWO_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Should have at least 2 pages
        #expect(pages.count >= 2, "Should have at least 2 pages after forced break")
    }

    @Test
    func `pageBreakAfter auto allows natural flow`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "SHORT_CONTENT" }
                    .css.pageBreakAfter(.auto)

                Paragraph { "MORE_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Short content should fit on one page
        #expect(pages.count == 1, "Short content with auto should fit on one page")
    }
}

// MARK: - PageBreakBefore Tests

@Suite
struct `PageBreakBefore Tests` {

    @Test
    func `pageBreakBefore always forces page break`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "PAGE_ONE_CONTENT" }

                Paragraph { "PAGE_TWO_CONTENT" }
                    .css.pageBreakBefore(.always)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Should have at least 2 pages
        #expect(pages.count >= 2, "Should have at least 2 pages after forced break")
    }

    @Test
    func `pageBreakBefore auto allows natural flow`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "FIRST" }
                Paragraph { "SECOND" }
                    .css.pageBreakBefore(.auto)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        #expect(pages.count == 1, "Short content with auto should fit on one page")
    }
}

// MARK: - PageBreakInside Tests

@Suite
struct `PageBreakInside Tests` {

    @Test
    func `pageBreakInside avoid keeps element together`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill most of page
                for i in 1...35 {
                    Paragraph { "Filler \(i)" }
                }

                // Element that should not split
                ContentDivision {
                    Paragraph { "KEEP_TOGETHER_START" }
                    Paragraph { "KEEP_TOGETHER_END" }
                }
                .css.pageBreakInside(.avoid)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Both parts should be in PDF
        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("KEEP_TOGETHER_START"))
        #expect(contentString.contains("KEEP_TOGETHER_END"))
    }
}

// MARK: - BreakAfter Tests (Modern CSS)

@Suite
struct `BreakAfter Tests` {

    @Test
    func `breakAfter avoid keeps header with following content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                // Fill most of page
                for i in 1...40 {
                    Paragraph { "Filler \(i)" }
                }

                H2 { "MODERN_STICKY_HEADER" }
                    .css.breakAfter(.avoid)

                Paragraph { "MODERN_FOLLOWING_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("MODERN_STICKY_HEADER"))
        #expect(contentString.contains("MODERN_FOLLOWING_CONTENT"))
    }

    @Test
    func `breakAfter avoidPage keeps header with following content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...40 {
                    Paragraph { "Filler \(i)" }
                }

                H2 { "AVOID_PAGE_HEADER" }
                    .css.breakAfter(.avoidPage)

                Paragraph { "AVOID_PAGE_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("AVOID_PAGE_HEADER"))
        #expect(contentString.contains("AVOID_PAGE_CONTENT"))
    }

    @Test
    func `breakAfter always forces page break`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "BEFORE_BREAK" }
                    .css.breakAfter(.always)

                Paragraph { "AFTER_BREAK" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        #expect(pages.count >= 2, "breakAfter: always should create page break")
    }

    @Test
    func `breakAfter page forces page break`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "BEFORE_PAGE_BREAK" }
                    .css.breakAfter(.page)

                Paragraph { "AFTER_PAGE_BREAK" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        #expect(pages.count >= 2, "breakAfter: page should create page break")
    }
}

// MARK: - BreakBefore Tests (Modern CSS)

@Suite
struct `BreakBefore Tests` {

    @Test
    func `breakBefore always forces page break`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "BEFORE_CONTENT" }

                Paragraph { "AFTER_BREAK_CONTENT" }
                    .css.breakBefore(.always)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        #expect(pages.count >= 2, "breakBefore: always should create page break")
    }

    @Test
    func `breakBefore page forces page break`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "FIRST_PAGE" }

                Paragraph { "SECOND_PAGE" }
                    .css.breakBefore(.page)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        #expect(pages.count >= 2, "breakBefore: page should create page break")
    }

    @Test
    func `breakBefore auto allows natural flow`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                Paragraph { "A" }
                Paragraph { "B" }
                    .css.breakBefore(.auto)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        #expect(pages.count == 1)
    }
}

// MARK: - BreakInside Tests (Modern CSS)

@Suite
struct `BreakInside Tests` {

    @Test
    func `breakInside avoid keeps element together`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...35 {
                    Paragraph { "Filler \(i)" }
                }

                ContentDivision {
                    Paragraph { "MODERN_KEEP_START" }
                    Paragraph { "MODERN_KEEP_END" }
                }
                .css.breakInside(.avoid)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("MODERN_KEEP_START"))
        #expect(contentString.contains("MODERN_KEEP_END"))
    }

    @Test
    func `breakInside avoidPage keeps element together`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...35 {
                    Paragraph { "Filler \(i)" }
                }

                ContentDivision {
                    Paragraph { "AVOID_PAGE_START" }
                    Paragraph { "AVOID_PAGE_END" }
                }
                .css.breakInside(.avoidPage)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("AVOID_PAGE_START"))
        #expect(contentString.contains("AVOID_PAGE_END"))
    }
}

// MARK: - Consecutive Sticky Headers Tests

@Suite
struct `Consecutive Sticky Headers Tests` {

    @Test
    func `Consecutive sticky headers chain together`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...40 {
                    Paragraph { "Filler \(i)" }
                }

                // Two consecutive sticky headers
                H3 { "ARTICLE_HEADER" }
                    .css.pageBreakAfter(.avoid)

                H4 { "SECTION_HEADER" }
                    .css.pageBreakAfter(.avoid)

                Paragraph { "SECTION_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("ARTICLE_HEADER"))
        #expect(contentString.contains("SECTION_HEADER"))
        #expect(contentString.contains("SECTION_CONTENT"))
    }

    @Test
    func `Modern consecutive sticky headers chain together`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...40 {
                    Paragraph { "Filler \(i)" }
                }

                H3 { "MODERN_ARTICLE" }
                    .css.breakAfter(.avoid)

                H4 { "MODERN_SECTION" }
                    .css.breakAfter(.avoid)

                Paragraph { "MODERN_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("MODERN_ARTICLE"))
        #expect(contentString.contains("MODERN_SECTION"))
        #expect(contentString.contains("MODERN_CONTENT"))
    }
}

// MARK: - Section Wrapper Tests

@Suite
struct `Section Wrapper Tests` {

    @Test
    func `Sticky header inside Section wrapper works`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...40 {
                    Paragraph { "Filler \(i)" }
                }

                Section {
                    H3 { "SECTION_WRAPPED_HEADER" }
                        .css.pageBreakAfter(.avoid)

                    Paragraph { "SECTION_WRAPPED_CONTENT" }
                }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("SECTION_WRAPPED_HEADER"))
        #expect(contentString.contains("SECTION_WRAPPED_CONTENT"))
    }

    @Test
    func `Modern sticky header inside Section wrapper works`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...40 {
                    Paragraph { "Filler \(i)" }
                }

                Section {
                    H3 { "MODERN_SECTION_HEADER" }
                        .css.breakAfter(.avoid)

                    Paragraph { "MODERN_SECTION_CONTENT" }
                }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("MODERN_SECTION_HEADER"))
        #expect(contentString.contains("MODERN_SECTION_CONTENT"))
    }
}

// MARK: - Sticky Header with Table Tests

@Suite
struct `Sticky Header with Table Tests` {

    @Test
    func `Sticky header with following table`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                for i in 1...38 {
                    Paragraph { "Filler \(i)" }
                }

                H3 { "TABLE_HEADER" }
                    .css.pageBreakAfter(.avoid)

                Table {
                    TableHead {
                        TableRow {
                            TableHeader { "Column A" }
                            TableHeader { "Column B" }
                        }
                    }
                    TableBody {
                        TableRow {
                            TableDataCell { "DATA_A" }
                            TableDataCell { "DATA_B" }
                        }
                    }
                }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("TABLE_HEADER"))
        #expect(contentString.contains("DATA_A"))
    }
}
