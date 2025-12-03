// tr.swift
// Table row element renderer
import PDF_Rendering
import HTML_Standard
import W3C_CSS_Fonts
extension TableRow {
    /// Renderer for the `<tr>` element.
    ///
    /// The `<tr>` element defines a row of cells in a table.
    /// It renders its child cells horizontally on a single line.
    public static func _renderToPDF(
        children: [any HTMLToPDFConvertible],
        style: HTML.ComputedStyle,
        context: inout PDF.Context,
        configuration: HTML.Configuration
    ) throws {
        let fontSize = style.fontSize ?? configuration.defaultFontSize
        // Render all cells inline on the same line with tab separators
        for (index, child) in children.enumerated() {
            // Add tab separator before each cell except the first
            if index > 0 {
                let font: PDF.Font = {
                    let isBold: Bool = {
                        guard let weight = style.fontWeight else { return false }
                        switch weight {
                        case .bold, .bolder: return true
                        case .number(let n) where n >= 600: return true
                        default: return false
                        }
                    }()
                    let isItalic: Bool = {
                        guard let fontStyle = style.fontStyle else { return false }
                        switch fontStyle {
                        case .italic, .oblique, .obliqueAngle: return true
                        default: return false
                        }
                    }()
                    switch (isBold, isItalic) {
                    case (true, true): return .helvetica.bold.italic
                    case (true, false): return .helvetica.bold
                    case (false, true): return .helvetica.italic
                    case (false, false): return .helvetica
                    }
                }()
                context.appendInlineRun(PDF.TextRun(
                    text: "        ",  // 8 spaces as column separator for visible separation
                    font: font,
                    fontSize: fontSize,
                    color: style.color ?? configuration.defaultColor
                ))
            }
            _ = HTML.renderToPDF(child, configuration: configuration, style: style, context: &context)
        }
        // Flush the row and move to next line
        _ = context.flushInlineRuns()
        context.advanceY(fontSize * 0.2)
    }
}
