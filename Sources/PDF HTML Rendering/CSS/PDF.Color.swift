//
//  File.swift
//  swift-pdf-html-rendering
//
//  Created by Coen ten Thije Boonkkamp on 04/12/2025.
//

import CSS_Standard
public import W3C_CSS_Values

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
