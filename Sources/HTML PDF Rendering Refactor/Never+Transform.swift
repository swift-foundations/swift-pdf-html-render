// Never+Transform.swift
// Never is uninhabited - transformation will never be called

import PDF_Rendering

extension Swift.Never: PDF.Transform {
    public static func _transform(
        _ view: Self,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        // Never is uninhabited - this will never be called
    }
}
