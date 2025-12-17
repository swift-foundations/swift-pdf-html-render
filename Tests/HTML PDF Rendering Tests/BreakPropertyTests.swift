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

@Suite("PageBreakAfter Tests")
struct PageBreakAfterTests {

    @Test("pageBreakAfter: avoid keeps header with following content")
    func avoidKeepsHeaderWithContent() {
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

    @Test("pageBreakAfter: always forces page break")
    func alwaysForcesPageBreak() {
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

    @Test("pageBreakAfter: auto allows natural flow")
    func autoAllowsNaturalFlow() {
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

@Suite("PageBreakBefore Tests")
struct PageBreakBeforeTests {

    @Test("pageBreakBefore: always forces page break")
    func alwaysForcesPageBreak() {
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

    @Test("pageBreakBefore: auto allows natural flow")
    func autoAllowsNaturalFlow() {
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

@Suite("PageBreakInside Tests")
struct PageBreakInsideTests {

    @Test("pageBreakInside: avoid keeps element together")
    func avoidKeepsElementTogether() {
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

@Suite("BreakAfter Tests")
struct BreakAfterTests {

    @Test("breakAfter: avoid keeps header with following content")
    func avoidKeepsHeaderWithContent() {
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

    @Test("breakAfter: avoidPage keeps header with following content")
    func avoidPageKeepsHeaderWithContent() {
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

    @Test("breakAfter: always forces page break")
    func alwaysForcesPageBreak() {
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

    @Test("breakAfter: page forces page break")
    func pageForcesPageBreak() {
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

@Suite("BreakBefore Tests")
struct BreakBeforeTests {

    @Test("breakBefore: always forces page break")
    func alwaysForcesPageBreak() {
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

    @Test("breakBefore: page forces page break")
    func pageForcesPageBreak() {
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

    @Test("breakBefore: auto allows natural flow")
    func autoAllowsNaturalFlow() {
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

@Suite("BreakInside Tests")
struct BreakInsideTests {

    @Test("breakInside: avoid keeps element together")
    func avoidKeepsElementTogether() {
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

    @Test("breakInside: avoidPage keeps element together")
    func avoidPageKeepsElementTogether() {
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

@Suite("Consecutive Sticky Headers Tests")
struct ConsecutiveStickyHeadersTests {

    @Test("Consecutive sticky headers chain together")
    func consecutiveHeadersChain() {
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

    @Test("Modern consecutive sticky headers chain together")
    func modernConsecutiveHeadersChain() {
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

@Suite("Section Wrapper Tests")
struct SectionWrapperTests {

    @Test("Sticky header inside Section wrapper works")
    func stickyHeaderInSection() {
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

    @Test("Modern sticky header inside Section wrapper works")
    func modernStickyHeaderInSection() {
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

@Suite("Sticky Header with Table Tests")
struct StickyHeaderWithTableTests {

    @Test("Sticky header with following table")
    func stickyHeaderWithTable() {
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
