// String+PDF.HTML.View.swift
// String is a leaf type - appends text run to context

import PDF_Rendering

extension String: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Append text as inline run (will be flushed at block boundaries)
        let run = PDF.TextRun(
            text: view,
            font: context.pdf.font,
            fontSize: context.pdf.fontSize,
            color: context.pdf.color,
            textDecoration: context.pdf.textDecoration,
            backgroundColor: context.pdf.textBackgroundColor
        )
        context.pdf.appendInlineRun(run)
    }
}
