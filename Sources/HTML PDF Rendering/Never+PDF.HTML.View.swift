// Never+PDF.HTML.View.swift
// Never is uninhabited - transformation will never be called

import PDF_Rendering

extension Swift.Never: PDF.HTML.View {
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context,
        configuration: PDF.HTML.Configuration
    ) where Buffer.Element == PDF.Render.Operation {
        // Never is uninhabited - this will never be called
    }
}
