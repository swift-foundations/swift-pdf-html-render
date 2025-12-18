// Never+PDF.HTML.View.swift
// Never is uninhabited - transformation will never be called

import PDF_Rendering

extension Swift.Never: PDF.HTML.View {
    public static func _render(
        _ view: Self,
        context: inout PDF.HTML.Context
    ) {
        // Never is uninhabited - this will never be called
    }
}
