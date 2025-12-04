// String+PDF.HTML.View.swift
// String is a leaf type - appends text run to context

import PDF_Rendering

extension String: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Append text as inline run (will be flushed at block boundaries)
        let run = PDF.TextRun(
            text: view,
            font: context.font,
            fontSize: context.fontSize,
            color: context.color,
            textDecoration: context.textDecoration,
            backgroundColor: context.textBackgroundColor
        )
        context.appendInlineRun(run)
    }
}
