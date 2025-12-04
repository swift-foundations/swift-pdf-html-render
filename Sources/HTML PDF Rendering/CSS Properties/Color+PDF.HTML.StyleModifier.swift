// Color+PDF.HTML.StyleModifier.swift
// CSS color property to PDF context translation
//
// Uses CSS Standard's IEC 61966-2-1 sRGB conversions.

import CSS_Standard
import PDF_Rendering
import W3C_CSS_Color
import W3C_CSS_Values

extension W3C_CSS_Color.Color: PDF.HTML.StyleModifier {
    public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
        switch self {
        case .color(let color):
            context.color = PDF.Color(color) ?? context.color
        case .global:
            // Inherit/initial/unset - no change for PDF
            break
        }
    }
}

// MARK: - CSS Color Value to PDF Color

extension PDF.Color {
    /// Create PDF color from CSS color value
    ///
    /// Uses CSS Standard's IEC 61966-2-1 sRGB conversions for all color types.
    ///
    /// - Parameter color: A CSS color value
    public init?(_ color: W3C_CSS_Values.Color) {
        // Use CSS Standard's sRGB.init?(Color) which handles all conversions
        guard let srgb = sRGB(color) else { return nil }
        self.init(srgb)
    }
}
