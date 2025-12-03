// String+Transform.swift
// String is a leaf type - appends text run to context

import PDF_Rendering

extension String: PDF.Transform {
    public static func _transform(
        _ view: Self,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        let run = PDF.TextRun(
            text: view,
            font: context.font,
            fontSize: context.fontSize,
            color: context.color
        )
        context.appendInlineRun(run)
    }
}
