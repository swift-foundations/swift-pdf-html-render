extension PDF.Color {

    public init?(_ color: W3C_CSS_Values.Color) {

        guard let srgb = sRGB(color) else { return nil }
        self.init(srgb)
    }
}
