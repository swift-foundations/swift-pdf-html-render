// String+PDF.HTML.View.swift
// String is a leaf type - appends text run to context

import PDF_Rendering

extension String: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Create text runs with automatic symbol font support
        // This handles characters like ✓ by switching to ZapfDingbats
        let runs = PDF.Context.TextRun.runsWithSymbolSupport(
            text: view,
            font: context.pdf.style.font,
            fontSize: context.pdf.style.fontSize,
            color: context.pdf.style.color,
            textDecoration: context.pdf.style.textMarkup,
            verticalOffset: context.pdf.style.verticalOffset,
            linkURL: context.link.currentURL,
            internalLinkId: context.link.currentInternalId
        )

        // Append all runs (will be flushed at block boundaries)
        for run in runs {
            context.pdf.append(inline: run)
        }
    }
}
