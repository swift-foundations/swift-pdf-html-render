import PDF_Standard
import W3C_CSS_Values
import ISO_9899

extension PDF.Color {
    /// Initialize from a CSS Color value
    ///
    /// Converts CSS color formats (named, hex, RGB, HSL, etc.) to PDF RGB/grayscale colors.
    ///
    /// Example:
    /// ```swift
    /// let red = PDF.Color(.named(.red))
    /// let hex = PDF.Color(.hex("#ff6600"))
    /// let rgb = PDF.Color(.rgb(255, 128, 0))
    /// ```
    ///
    /// - Parameter cssColor: The CSS color to convert
    public init(_ cssColor: W3C_CSS_Values.Color) {
        switch cssColor {
        case .named(let named):
            self = Self.fromNamed(named)

        case .hex(let hex):
            // HexColor stores the hex string
            if let color = PDF.Color(hex: hex.description) {
                self = color
            } else {
                self = .black
            }

        case .rgb(let r, let g, let b):
            self = .rgb(r: Double(r) / 255.0, g: Double(g) / 255.0, b: Double(b) / 255.0)

        case .rgba(let r, let g, let b, _):
            // PDF doesn't support alpha directly in colors, ignore alpha
            self = .rgb(r: Double(r) / 255.0, g: Double(g) / 255.0, b: Double(b) / 255.0)

        case .hsl(let h, let s, let l):
            let (r, g, b) = Self.hslToRgb(h: h.degrees, s: s / 100.0, l: l / 100.0)
            self = .rgb(r: r, g: g, b: b)

        case .hsla(let h, let s, let l, _):
            let (r, g, b) = Self.hslToRgb(h: h.degrees, s: s / 100.0, l: l / 100.0)
            self = .rgb(r: r, g: g, b: b)

        case .hwb(let h, let w, let bk):
            let (r, g, b) = Self.hwbToRgb(h: h.degrees, w: w / 100.0, b: bk / 100.0)
            self = .rgb(r: r, g: g, b: b)

        case .lab(let l, let a, let b):
            let (r, g, b_val) = Self.labToRgb(l: l, a: a, b: b)
            self = .rgb(r: r, g: g, b: b_val)

        case .lch(let l, let c, let h):
            // Convert LCH to Lab first
            let a = c * ISO_9899.Math.cos(h * .pi / 180.0)
            let b = c * ISO_9899.Math.sin(h * .pi / 180.0)
            let (r, g, b_val) = Self.labToRgb(l: l, a: a, b: b)
            self = .rgb(r: r, g: g, b: b_val)

        case .oklab(let l, let a, let b):
            let (r, g, b_val) = Self.oklabToRgb(l: l, a: a, b: b)
            self = .rgb(r: r, g: g, b: b_val)

        case .oklch(let l, let c, let h):
            let a = c * ISO_9899.Math.cos(h * .pi / 180.0)
            let b = c * ISO_9899.Math.sin(h * .pi / 180.0)
            let (r, g, b_val) = Self.oklabToRgb(l: l, a: a, b: b)
            self = .rgb(r: r, g: g, b: b_val)

        case .mix:
            // Color mixing would require full implementation - fallback
            self = .gray50

        case .system:
            // System colors are context-dependent - use sensible defaults
            self = .black

        case .currentColor:
            // Should be resolved in context - fallback to black
            self = .black

        case .transparent:
            // PDF doesn't support transparency in color - use white
            self = .white
        }
    }

    // MARK: - Named Color Conversion

    private static func fromNamed(_ named: W3C_CSS_Values.NamedColor) -> PDF.Color {
        // Use the named color's description to parse as hex
        // NamedColor.description returns the color name, but we can try to map common ones
        let name = String(describing: named).lowercased()

        // Map common CSS named colors to RGB values
        switch name {
        case "black": return .black
        case "white": return .white
        case "red": return .red
        case "green": return .rgb(r: 0, g: 128.0/255.0, b: 0)  // CSS green is #008000
        case "blue": return .blue
        case "gray", "grey": return .gray50
        case "silver": return .rgb(r: 192.0/255.0, g: 192.0/255.0, b: 192.0/255.0)
        case "maroon": return .rgb(r: 128.0/255.0, g: 0, b: 0)
        case "purple": return .rgb(r: 128.0/255.0, g: 0, b: 128.0/255.0)
        case "fuchsia", "magenta": return .rgb(r: 1, g: 0, b: 1)
        case "lime": return .rgb(r: 0, g: 1, b: 0)
        case "olive": return .rgb(r: 128.0/255.0, g: 128.0/255.0, b: 0)
        case "yellow": return .rgb(r: 1, g: 1, b: 0)
        case "navy": return .rgb(r: 0, g: 0, b: 128.0/255.0)
        case "teal": return .rgb(r: 0, g: 128.0/255.0, b: 128.0/255.0)
        case "aqua", "cyan": return .rgb(r: 0, g: 1, b: 1)
        case "orange": return .rgb(r: 1, g: 165.0/255.0, b: 0)
        case "pink": return .rgb(r: 1, g: 192.0/255.0, b: 203.0/255.0)
        case "brown": return .rgb(r: 165.0/255.0, g: 42.0/255.0, b: 42.0/255.0)
        case "coral": return .rgb(r: 1, g: 127.0/255.0, b: 80.0/255.0)
        case "crimson": return .rgb(r: 220.0/255.0, g: 20.0/255.0, b: 60.0/255.0)
        case "darkblue": return .rgb(r: 0, g: 0, b: 139.0/255.0)
        case "darkgray", "darkgrey": return .darkGray
        case "darkgreen": return .rgb(r: 0, g: 100.0/255.0, b: 0)
        case "darkred": return .rgb(r: 139.0/255.0, g: 0, b: 0)
        case "gold": return .rgb(r: 1, g: 215.0/255.0, b: 0)
        case "indigo": return .rgb(r: 75.0/255.0, g: 0, b: 130.0/255.0)
        case "lightblue": return .rgb(r: 173.0/255.0, g: 216.0/255.0, b: 230.0/255.0)
        case "lightgray", "lightgrey": return .lightGray
        case "lightgreen": return .rgb(r: 144.0/255.0, g: 238.0/255.0, b: 144.0/255.0)
        case "tomato": return .rgb(r: 1, g: 99.0/255.0, b: 71.0/255.0)
        case "violet": return .rgb(r: 238.0/255.0, g: 130.0/255.0, b: 238.0/255.0)
        default:
            // For any other named colors, fallback to black
            return .black
        }
    }

    // MARK: - Color Space Conversions

    /// Convert HSL to RGB (all values in 0-1 range)
    private static func hslToRgb(h: Double, s: Double, l: Double) -> (r: Double, g: Double, b: Double) {
        let hue = h.truncatingRemainder(dividingBy: 360) / 360.0

        if s == 0 {
            return (l, l, l)
        }

        let q = l < 0.5 ? l * (1 + s) : l + s - l * s
        let p = 2 * l - q

        func hueToRgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1/6 { return p + (q - p) * 6 * t }
            if t < 1/2 { return q }
            if t < 2/3 { return p + (q - p) * (2/3 - t) * 6 }
            return p
        }

        return (
            r: hueToRgb(p, q, hue + 1/3),
            g: hueToRgb(p, q, hue),
            b: hueToRgb(p, q, hue - 1/3)
        )
    }

    /// Convert HWB to RGB
    private static func hwbToRgb(h: Double, w: Double, b: Double) -> (r: Double, g: Double, b: Double) {
        var white = w
        var black = b

        // Normalize if w + b >= 1
        if white + black >= 1 {
            let sum = white + black
            white = white / sum
            black = black / sum
        }

        // Get base RGB from hue
        let (r, g, bl) = hslToRgb(h: h, s: 1, l: 0.5)

        // Apply whiteness and blackness
        return (
            r: r * (1 - white - black) + white,
            g: g * (1 - white - black) + white,
            b: bl * (1 - white - black) + white
        )
    }

    /// Convert Lab to RGB (simplified conversion)
    private static func labToRgb(l: Double, a: Double, b: Double) -> (r: Double, g: Double, b: Double) {
        // Convert Lab to XYZ
        var y = (l + 16) / 116
        var x = a / 500 + y
        var z = y - b / 200

        let y3 = y * y * y
        let x3 = x * x * x
        let z3 = z * z * z

        y = y3 > 0.008856 ? y3 : (y - 16.0/116) / 7.787
        x = x3 > 0.008856 ? x3 : (x - 16.0/116) / 7.787
        z = z3 > 0.008856 ? z3 : (z - 16.0/116) / 7.787

        // D65 illuminant
        x *= 0.95047
        y *= 1.0
        z *= 1.08883

        // XYZ to sRGB
        var r = x * 3.2406 + y * -1.5372 + z * -0.4986
        var g = x * -0.9689 + y * 1.8758 + z * 0.0415
        var bl = x * 0.0557 + y * -0.2040 + z * 1.0570

        // Gamma correction
        r = r > 0.0031308 ? 1.055 * ISO_9899.Math.pow(r, 1/2.4) - 0.055 : 12.92 * r
        g = g > 0.0031308 ? 1.055 * ISO_9899.Math.pow(g, 1/2.4) - 0.055 : 12.92 * g
        bl = bl > 0.0031308 ? 1.055 * ISO_9899.Math.pow(bl, 1/2.4) - 0.055 : 12.92 * bl

        return (r: max(0, min(1, r)), g: max(0, min(1, g)), b: max(0, min(1, bl)))
    }

    /// Convert Oklab to RGB
    private static func oklabToRgb(l: Double, a: Double, b: Double) -> (r: Double, g: Double, b: Double) {
        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        let l3 = l_ * l_ * l_
        let m3 = m_ * m_ * m_
        let s3 = s_ * s_ * s_

        var r = +4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
        var g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
        var bl = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

        // Gamma correction
        r = r > 0.0031308 ? 1.055 * ISO_9899.Math.pow(r, 1/2.4) - 0.055 : 12.92 * r
        g = g > 0.0031308 ? 1.055 * ISO_9899.Math.pow(g, 1/2.4) - 0.055 : 12.92 * g
        bl = bl > 0.0031308 ? 1.055 * ISO_9899.Math.pow(bl, 1/2.4) - 0.055 : 12.92 * bl

        return (r: max(0, min(1, r)), g: max(0, min(1, g)), b: max(0, min(1, bl)))
    }
}

// MARK: - Hue Helper

extension W3C_CSS_Values.Hue {
    /// Get degrees value from Hue
    var degrees: Double {
        normalizedDegrees()
    }
}
