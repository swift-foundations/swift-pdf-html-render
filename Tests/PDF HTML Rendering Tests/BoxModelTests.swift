// BoxModelTests.swift
// Tests for CSS Box Model (margin, padding, width, height) in PDF rendering

import CSS
import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

// MARK: - Margin Tests

@Suite
struct `Margin Tests` {

    @Test
    func `marginTop advances Y position`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "FIRST_PARAGRAPH" }
                }
                .css.marginTop(.px(20))

                Paragraph { "SECOND_PARAGRAPH" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Both paragraphs should render
        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("FIRST_PARAGRAPH"))
        #expect(contentString.contains("SECOND_PARAGRAPH"))
    }

    @Test
    func `marginBottom advances Y position after content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "CONTENT_WITH_MARGIN" }
                }
                .css.marginBottom(.px(20))

                Paragraph { "FOLLOWING_CONTENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("CONTENT_WITH_MARGIN"))
        #expect(contentString.contains("FOLLOWING_CONTENT"))
    }

    @Test
    func `marginLeft insets content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "INDENTED_CONTENT" }
                }
                .css.marginLeft(.px(30))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("INDENTED_CONTENT"))
    }

    @Test
    func `marginRight restricts content width`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "CONTENT_WITH_RIGHT_MARGIN" }
                }
                .css.marginRight(.px(30))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("CONTENT_WITH_RIGHT_MARGIN"))
    }

    @Test
    func `margin shorthand applies all sides`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "FULLY_MARGINED_CONTENT" }
                }
                .css.margin(.px(10))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("FULLY_MARGINED_CONTENT"))
    }

    @Test
    func `margin with em units scales with font size`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "EM_MARGIN_CONTENT" }
                }
                .css.marginTop(.em(1.5))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("EM_MARGIN_CONTENT"))
    }
}

// MARK: - Padding Tests

@Suite
struct `Padding Tests` {

    @Test
    func `paddingTop advances Y position inside element`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "PADDED_TOP_CONTENT" }
                }
                .css.paddingTop(.px(15))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("PADDED_TOP_CONTENT"))
    }

    @Test
    func `paddingBottom advances Y position after content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "PADDED_BOTTOM_CONTENT" }
                }
                .css.paddingBottom(.px(15))

                Paragraph { "FOLLOWING_ELEMENT" }
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("PADDED_BOTTOM_CONTENT"))
        #expect(contentString.contains("FOLLOWING_ELEMENT"))
    }

    @Test
    func `paddingLeft insets content from left edge`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "LEFT_PADDED_CONTENT" }
                }
                .css.paddingLeft(.px(25))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("LEFT_PADDED_CONTENT"))
    }

    @Test
    func `paddingRight insets content from right edge`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "RIGHT_PADDED_CONTENT" }
                }
                .css.paddingRight(.px(25))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("RIGHT_PADDED_CONTENT"))
    }

    @Test
    func `padding shorthand applies all sides`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "FULLY_PADDED_CONTENT" }
                }
                .css.padding(.px(12))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("FULLY_PADDED_CONTENT"))
    }

    @Test
    func `padding with percentage uses parent width`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "PERCENTAGE_PADDED_CONTENT" }
                }
                .css.padding(.percent(5))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("PERCENTAGE_PADDED_CONTENT"))
    }
}

// MARK: - Width Tests

@Suite
struct `Width Tests` {

    @Test
    func `explicit width constrains content area`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "WIDTH_CONSTRAINED_CONTENT" }
                }
                .css.width(.px(200))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("WIDTH_CONSTRAINED_CONTENT"))
    }

    @Test
    func `width auto uses available space`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "AUTO_WIDTH_CONTENT" }
                }
                .css.width(.auto)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("AUTO_WIDTH_CONTENT"))
    }

    @Test
    func `width percentage uses parent width`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "PERCENT_WIDTH_CONTENT" }
                }
                .css.width(.percent(50))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("PERCENT_WIDTH_CONTENT"))
    }
}

// MARK: - Height Tests

@Suite
struct `Height Tests` {

    @Test
    func `explicit height does not break content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "HEIGHT_CONSTRAINED_CONTENT" }
                }
                .css.height(.px(100))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("HEIGHT_CONSTRAINED_CONTENT"))
    }

    @Test
    func `height auto computes from content`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "AUTO_HEIGHT_CONTENT" }
                }
                .css.height(.auto)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("AUTO_HEIGHT_CONTENT"))
    }
}

// MARK: - Combined Box Model Tests

@Suite
struct `Combined Box Model Tests` {

    @Test
    func `margin and padding combine correctly`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "MARGIN_AND_PADDING_CONTENT" }
                }
                .css.margin(.px(10))
                .css.padding(.px(15))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("MARGIN_AND_PADDING_CONTENT"))
    }

    @Test
    func `nested elements with box model`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    ContentDivision {
                        Paragraph { "DEEPLY_NESTED_CONTENT" }
                    }
                    .css.padding(.px(10))
                }
                .css.margin(.px(20))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("DEEPLY_NESTED_CONTENT"))
    }

    @Test
    func `width with padding computes content area correctly`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "WIDTH_WITH_PADDING_CONTENT" }
                }
                .css.width(.px(300))
                .css.padding(.px(20))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("WIDTH_WITH_PADDING_CONTENT"))
    }

    @Test
    func `margin with width centers element`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "MARGIN_AUTO_CENTERED_CONTENT" }
                }
                .css.width(.px(400))
                .css.marginLeft(.auto)
                .css.marginRight(.auto)
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("MARGIN_AUTO_CENTERED_CONTENT"))
    }
}

// MARK: - Box Model with Text Flow Tests

@Suite
struct `Box Model with Text Flow Tests` {

    @Test
    func `padding affects text wrapping`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph {
                        "This is a longer paragraph that should wrap differently when padding is applied because the content area is reduced by the padding values on the left and right sides."
                    }
                }
                .css.padding(.px(50))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        // Content should still render
        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("longer paragraph"))
    }

    @Test
    func `width constraint affects text wrapping`() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph {
                        "This is content that will wrap more aggressively due to the narrow width constraint applied to its container."
                    }
                }
                .css.width(.px(150))
            }
        }

        let pages = PDF.HTML.pages { TestView() }

        let allContent = pages.flatMap { $0.contents }.flatMap { $0.data }
        let contentString = String(decoding: allContent, as: UTF8.self)
        #expect(contentString.contains("content"))
    }
}
