// KeyboardInput+PDF.HTML.View.swift
// <kbd> element transformation - keyboard input

import HTML_Renderable
import PDF_Rendering
import WHATWG_HTML

extension KeyboardInput: PDF.HTML.TagRenderer {
    static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        // Keyboard input is rendered in monospace (browser default)
        context.style.font = .courier
    }
}
