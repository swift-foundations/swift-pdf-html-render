import PDF_Standard
import W3C_CSS_Values

extension PDF {
    /// A value in PDF points (1/72 inch), converted from CSS length units.
    ///
    /// This type provides type-safe conversion from CSS length values to PDF points,
    /// which are the native unit for PDF rendering.
    ///
    /// Example:
    /// ```swift
    /// let points = PDF.Points(.px(16))  // 12pt (16px * 0.75)
    /// let em = PDF.Points(.em(2), relativeTo: 12)  // 24pt
    /// ```
    public struct Points: Sendable, Hashable {
        /// The value in points
        public let value: Double

        /// Initialize with a raw points value
        public init(_ value: Double) {
            self.value = value
        }

        /// Initialize from a CSS Length value
        ///
        /// - Parameters:
        ///   - length: The CSS length to convert
        ///   - base: The base font size for relative units (em, rem). Defaults to 12pt.
        public init(_ length: W3C_CSS_Values.Length, relativeTo base: Double = 12.0) {
            switch length {
            case .length(let val, let unit):
                switch unit {
                case .px:
                    // CSS pixels are 1/96 inch, PDF points are 1/72 inch
                    // 96/72 = 1.333..., so px * 0.75 = points
                    self.value = val * 0.75
                case .pt:
                    // Points map directly
                    self.value = val
                case .em:
                    // Relative to current font size
                    self.value = val * base
                case .rem:
                    // Relative to root font size (assume 16px = 12pt default)
                    self.value = val * 12.0
                case .cm:
                    // 1 cm = 28.3465 points
                    self.value = val * 28.3465
                case .mm:
                    // 1 mm = 2.83465 points
                    self.value = val * 2.83465
                case .in:
                    // 1 inch = 72 points
                    self.value = val * 72.0
                case .pc:
                    // 1 pica = 12 points
                    self.value = val * 12.0
                case .ex:
                    // Approximate: x-height is roughly 0.5em
                    self.value = val * base * 0.5
                case .ch:
                    // Approximate: character width is roughly 0.5em
                    self.value = val * base * 0.5
                case .lh:
                    // Line height: use base * 1.2 as typical line height
                    self.value = val * base * 1.2
                case .vw, .vh, .vmin, .vmax:
                    // Viewport units not applicable to PDF - fallback to 0
                    self.value = 0
                case .fr:
                    // Grid fraction units not applicable here
                    self.value = 0
                case .q:
                    // Quarter-millimeter
                    self.value = val * 0.708663
                case .cap:
                    // Cap height approximation
                    self.value = val * base * 0.7
                case .ic:
                    // Ideographic character width (approximate as 1em)
                    self.value = val * base
                case .rlh:
                    // Root line height
                    self.value = val * 12.0 * 1.2
                }
            case .keyword(let kw):
                switch kw {
                case .auto, .maxContent, .minContent, .fitContent:
                    // Keywords resolve to 0 (context-dependent in actual layout)
                    self.value = 0
                }
            case .calc:
                // calc() expressions would need parsing - fallback to 0
                self.value = 0
            case .global:
                // Global values (inherit, initial, etc.) - fallback to 0
                self.value = 0
            }
        }
    }
}

// MARK: - Convenience

extension PDF.Points: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.value = Double(value)
    }
}

extension PDF.Points: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.value = value
    }
}
