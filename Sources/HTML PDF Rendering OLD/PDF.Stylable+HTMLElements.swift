// PDF.Stylable+HTMLElements.swift
// PDF.Stylable conformances for HTML element marker types

import PDF_Rendering
import HTML_Standard

// MARK: - Headings

extension H1: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontSize: 32, fontWeight: .bold, spacingBefore: 0.5, spacingAfter: 0.3)
    }
}

extension H2: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontSize: 24, fontWeight: .bold, spacingBefore: 0.4, spacingAfter: 0.25)
    }
}

extension H3: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontSize: 20, fontWeight: .bold, spacingBefore: 0.35, spacingAfter: 0.2)
    }
}

extension H4: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontSize: 16, fontWeight: .bold, spacingBefore: 0.3, spacingAfter: 0.15)
    }
}

extension H5: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontSize: 14, fontWeight: .bold, spacingBefore: 0.25, spacingAfter: 0.1)
    }
}

extension H6: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontSize: 12, fontWeight: .bold, spacingBefore: 0.2, spacingAfter: 0.1)
    }
}

// MARK: - Text Blocks

extension Paragraph: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0, spacingAfter: 0.5)
    }
}

extension BlockQuote: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        PDF.Style(
            italic: true,
            spacingBefore: 0.3,
            spacingAfter: 0.3,
            isBlock: true
        )
    }
}

extension PreformattedText: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

// MARK: - Inline Text Formatting

extension StrongImportance: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(fontWeight: .bold)
    }
}

extension B: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(fontWeight: .bold)
    }
}

extension Emphasis: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(italic: true)
    }
}

extension IdiomaticText: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(italic: true)
    }
}

extension UnarticulatedAnnotation: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(underline: true)
    }
}

extension Strikethrough: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(strikethrough: true)
    }
}

extension Code: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        // Code uses monospace font - handle in rendering
        .inline(backgroundColor: .gray(0.95))
    }
}

extension Mark: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(backgroundColor: .rgb(r: 1, g: 1, b: 0))
    }
}

extension Small: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        // Small text - reduce font size proportionally
        PDF.Style(fontSize: 10, isBlock: false)
    }
}

extension Subscript: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        PDF.Style(fontSize: 10, isBlock: false)
    }
}

extension Superscript: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        PDF.Style(fontSize: 10, isBlock: false)
    }
}

// MARK: - Containers/Sections

extension ContentDivision: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

extension ContentSpan: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline()
    }
}

extension Section: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

extension Article: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.3, spacingAfter: 0.3)
    }
}

extension Header: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingAfter: 0.2)
    }
}

extension Footer: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2)
    }
}

extension Main: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

extension Aside: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        PDF.Style(
            italic: true,
            spacingBefore: 0.2,
            spacingAfter: 0.2,
            isBlock: true
        )
    }
}

extension NavigationSection: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

// MARK: - Links

extension Anchor: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(underline: true, color: .rgb(r: 0, g: 0, b: 0.8))
    }
}

// MARK: - Lists

extension UnorderedList: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

extension OrderedList: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

extension ListItem: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingAfter: 0.1)
    }
}

// MARK: - Tables

extension Table: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.3, spacingAfter: 0.3)
    }
}

extension TableHead: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontWeight: .bold)
    }
}

extension TableBody: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

extension TableFoot: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

extension TableRow: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

extension TableHeader: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(fontWeight: .bold)
    }
}

extension TableDataCell: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline()
    }
}

extension Caption: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        PDF.Style(italic: true, spacingAfter: 0.2, isBlock: true)
    }
}

// MARK: - Media

extension Image: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

extension Figure: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.3, spacingAfter: 0.3)
    }
}

extension FigureCaption: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        PDF.Style(italic: true, spacingBefore: 0.1, isBlock: true)
    }
}

extension Picture: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

// MARK: - Form Elements

extension Form: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

extension Input: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline()
    }
}

extension Button: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline(fontWeight: .bold)
    }
}

extension Select: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline()
    }
}

extension Option: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline()
    }
}

extension Textarea: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

extension Label: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .inline()
    }
}

extension FieldSet: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

extension Legend: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontWeight: .bold, spacingAfter: 0.1)
    }
}

// MARK: - Interactive Elements

extension Details: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.2, spacingAfter: 0.2)
    }
}

extension DisclosureSummary: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(fontWeight: .bold)
    }
}

extension Dialog: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.3, spacingAfter: 0.3)
    }
}

// MARK: - Void Elements

extension BR: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block()
    }
}

extension ThematicBreak: PDF.Stylable {
    public static var pdfStyle: PDF.Style {
        .block(spacingBefore: 0.3, spacingAfter: 0.3)
    }
}
