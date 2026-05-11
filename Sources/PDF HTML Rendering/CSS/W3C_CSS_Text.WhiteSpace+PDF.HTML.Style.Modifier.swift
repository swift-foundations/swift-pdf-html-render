// W3C_CSS_Text.WhiteSpace+PDF.HTML.Style.Modifier.swift
// CSS white-space property to PDF context translation

import PDF_Rendering
import PDF_Standard

extension W3C_CSS_Text.WhiteSpace: PDF.HTML.Style.Modifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .normal, .nowrap, .preLine:
            // CSS collapses whitespace sequences for `normal`, `nowrap`,
            // and `pre-line`. `nowrap` adds suppress-wrap semantics
            // (deferred to a line-breaker enhancement); `pre-line` adds
            // newline preservation (also deferred). The whitespace-
            // collapse property is the part the institute renderer reads
            // today; toggle it off so adjacent text runs are merged.
            context.mode.preserveWhitespace = false
        case .pre, .preWrap, .breakSpaces:
            // These three values preserve whitespace sequences verbatim
            // per CSS 2.1 §16.6; the renderer's `preserveWhitespace`
            // mode keeps the bytes as-emitted.
            context.mode.preserveWhitespace = true
        case .global:
            break
        }
    }
}
