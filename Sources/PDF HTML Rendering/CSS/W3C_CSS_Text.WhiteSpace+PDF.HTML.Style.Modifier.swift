// W3C_CSS_Text.WhiteSpace+PDF.HTML.Style.Modifier.swift
// CSS white-space property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Text.WhiteSpace: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Per CSS 2.1 §16.6 / CSS Text 3 §3, `white-space` is a shorthand
        // controlling two independent line-layout dimensions:
        //   • whitespace collapse — whether runs of WS are merged
        //   • line-wrap on overflow — whether content can break on soft
        //     break opportunities to fit `width`
        // The institute renderer models these as `mode.preserveWhitespace`
        // and `mode.noWrap` respectively. `pre-line` (collapse spaces but
        // preserve `\n`) needs newline-preservation we do not model today
        // and is approximated as `.normal`.
        switch self {
        case .normal:
            context.mode.preserveWhitespace = false
            context.mode.noWrap = false

        case .nowrap:
            context.mode.preserveWhitespace = false
            context.mode.noWrap = true

        case .pre:
            context.mode.preserveWhitespace = true
            context.mode.noWrap = true

        case .preWrap, .breakSpaces:
            context.mode.preserveWhitespace = true
            context.mode.noWrap = false

        case .preLine:
            context.mode.preserveWhitespace = false
            context.mode.noWrap = false

        case .global:
            break
        }
    }
}
