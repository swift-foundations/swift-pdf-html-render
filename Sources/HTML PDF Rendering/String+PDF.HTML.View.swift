// String+PDF.HTML.View.swift
// String is a leaf type - appends text run to context

import PDF_Rendering

extension String: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Append text as inline run (will be flushed at block boundaries)
        let run = PDF.Context.TextRun(
            text: view,
            font: context.pdf.style.font,
            fontSize: context.pdf.style.fontSize,
            color: context.pdf.style.color,
            textDecoration: context.pdf.style.textMarkup,
            verticalOffset: context.pdf.style.verticalOffset
        )
        context.pdf.append(inline: run)
    }
}
