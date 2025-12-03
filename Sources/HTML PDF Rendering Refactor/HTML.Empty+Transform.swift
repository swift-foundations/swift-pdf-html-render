// HTML.Empty+Transform.swift
// HTML.Empty renders nothing

import HTML_Renderable
import PDF_Rendering

extension HTML.Empty: PDF.Transform {
    public static func _transform(
        _ view: Self,
        context: inout PDF.Context,
        configuration: PDFTransformConfiguration
    ) {
        // Empty renders nothing
    }
}
