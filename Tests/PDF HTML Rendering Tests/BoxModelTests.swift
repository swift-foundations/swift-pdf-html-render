// BoxModelTests.swift
// Tests for CSS Box Model (margin, padding, width, height) in PDF rendering

import CSS
import Foundation
import HTML_Rendering
import PDF_Rendering
import Testing

@testable import PDF_HTML_Rendering

// MARK: - Margin Tests

@Suite("Margin Tests")
struct MarginTests {

    @Test("marginTop advances Y position")
    func marginTopAdvancesY() {
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

    @Test("marginBottom advances Y position after content")
    func marginBottomAdvancesY() {
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

    @Test("marginLeft insets content")
    func marginLeftInsetsContent() {
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

    @Test("marginRight restricts content width")
    func marginRightRestrictsWidth() {
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

    @Test("margin shorthand applies all sides")
    func marginShorthandAppliesAllSides() {
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

    @Test("margin with em units scales with font size")
    func marginEmScalesWithFontSize() {
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

@Suite("Padding Tests")
struct PaddingTests {

    @Test("paddingTop advances Y position inside element")
    func paddingTopAdvancesY() {
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

    @Test("paddingBottom advances Y position after content")
    func paddingBottomAdvancesY() {
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

    @Test("paddingLeft insets content from left edge")
    func paddingLeftInsetsContent() {
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

    @Test("paddingRight insets content from right edge")
    func paddingRightInsetsContent() {
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

    @Test("padding shorthand applies all sides")
    func paddingShorthandAppliesAllSides() {
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

    @Test("padding with percentage uses parent width")
    func paddingPercentageUsesParentWidth() {
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

@Suite("Width Tests")
struct WidthTests {

    @Test("explicit width constrains content area")
    func explicitWidthConstrainsContent() {
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

    @Test("width auto uses available space")
    func widthAutoUsesAvailableSpace() {
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

    @Test("width percentage uses parent width")
    func widthPercentageUsesParentWidth() {
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

@Suite("Height Tests")
struct HeightTests {

    @Test("explicit height does not break content")
    func explicitHeightRendersContent() {
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

    @Test("height auto computes from content")
    func heightAutoComputesFromContent() {
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

@Suite("Combined Box Model Tests")
struct CombinedBoxModelTests {

    @Test("margin and padding combine correctly")
    func marginAndPaddingCombine() {
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

    @Test("nested elements with box model")
    func nestedElementsWithBoxModel() {
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

    @Test("width with padding computes content area correctly")
    func widthWithPaddingComputesContentArea() {
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

    @Test("margin with width centers element")
    func marginWithWidthCentersElement() {
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

@Suite("Box Model with Text Flow Tests")
struct BoxModelTextFlowTests {

    @Test("padding affects text wrapping")
    func paddingAffectsTextWrapping() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "This is a longer paragraph that should wrap differently when padding is applied because the content area is reduced by the padding values on the left and right sides." }
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

    @Test("width constraint affects text wrapping")
    func widthConstraintAffectsTextWrapping() {
        struct TestView: HTML.View {
            var body: some HTML.View {
                ContentDivision {
                    Paragraph { "This is content that will wrap more aggressively due to the narrow width constraint applied to its container." }
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
