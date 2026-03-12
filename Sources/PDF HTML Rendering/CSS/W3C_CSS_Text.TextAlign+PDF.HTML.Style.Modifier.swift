// W3C_CSS_Text.TextAlign+PDF.HTML.Style.Modifier.swift
// CSS text-align property to PDF context translation

import Layout_Primitives
import PDF_Rendering
import PDF_Standard
public import W3C_CSS_Text

extension W3C_CSS_Text.TextAlign: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .left, .start:
            context.style.textAlign = .leading
        case .center:
            context.style.textAlign = .center
        case .right, .end:
            context.style.textAlign = .trailing
        case .justify:
            // Justify not fully supported - fall back to leading
            context.style.textAlign = .leading
        default:
            break
        }
    }
}
