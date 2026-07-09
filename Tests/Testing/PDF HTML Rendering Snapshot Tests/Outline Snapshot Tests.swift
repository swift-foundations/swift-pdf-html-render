//
//  Outline Snapshot Tests.swift
//  swift-pdf-html-rendering
//

import HTML_Rendering
import PDF_HTML_Rendering
import PDF_Rendering
import Test_Snapshot_Primitives
import Testing
import Tests_Inline_Snapshot

@Suite
struct OutlineSnapshotTests {
    @Suite struct Snapshot {}
}

// MARK: - Snapshot

extension OutlineSnapshotTests.Snapshot {
    @Test
    func `outline generation`() {
        let document = PDF.Document(generateOutline: true) {
            HTML.Document {
                H1 { "Chapter 1: Introduction" }
                Paragraph { "Introduction content goes here." }
                H2 { "1.1 Background" }
                Paragraph { "Background information." }
                H2 { "1.2 Objectives" }
                Paragraph { "Project objectives." }
                H3 { "1.2.1 Primary Goals" }
                Paragraph { "Primary goals description." }
                H1 { "Chapter 2: Method" }
                Paragraph { "Method description." }
                H2 { "2.1 Approach" }
                Paragraph { "Approach details." }
            }
        }

        snapshot(as: .pdf, named: "outline-generation") { document }
    }

    @Test
    func `articles of incorporation style`() {
        let document = PDF.Document(generateOutline: true) {
            HTML.Document {
                H1 { "Articles of Incorporation" }
                    .css.textAlign(.center)

                H2 { "Article I: Name" }
                Paragraph { "The name of the corporation shall be Test Corp." }

                H2 { "Article II: Purpose" }
                Paragraph { "The purpose of the corporation is to engage in any lawful activity." }

                H2 { "Article III: Capital Stock" }
                H3 { "Section 3.1: Authorized Shares" }
                Paragraph { "The total number of shares shall be 10,000." }
                H3 { "Section 3.2: Par Value" }
                Paragraph { "Each share shall have a par value of $0.01." }
                H3 { "Section 3.3: Classes of Stock" }
                Paragraph { "There shall be two classes: Common and Preferred." }

                H2 { "Article IV: Registered Agent" }
                Paragraph { "The registered agent shall be located at the principal office." }

                H2 { "Article V: Directors" }
                Paragraph { "The initial board shall consist of three directors." }
            }
        }

        snapshot(as: .pdf, named: "articles-of-incorporation") { document }
    }

    @Test
    func `single H1 parent`() {
        let document = PDF.Document(generateOutline: true) {
            HTML.Document {
                H1 { "Main Document" }
                Paragraph { "Introduction paragraph." }
                H3 { "Section 1" }
                Paragraph { "Content for section 1." }
                H3 { "Section 2" }
                Paragraph { "Content for section 2." }
                H3 { "Section 3" }
                Paragraph { "Content for section 3." }
            }
        }

        snapshot(as: .pdf, named: "single-h1-parent") { document }
    }

    @Test
    func `multiple H1 parents`() {
        let document = PDF.Document(generateOutline: true) {
            HTML.Document {
                H1 { "First Chapter" }
                Paragraph { "Content." }
                H3 { "First Section 1" }
                Paragraph { "Content." }
                H3 { "First Section 2" }
                Paragraph { "Content." }
                H1 { "Second Chapter" }
                Paragraph { "Content." }
                H3 { "Second Section 1" }
                Paragraph { "Content." }
                H3 { "Second Section 2" }
                Paragraph { "Content." }
            }
        }

        snapshot(as: .pdf, named: "multiple-h1-parents") { document }
    }
}
