// PDF.Color.swift
// CSS color to PDF color conversion

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
