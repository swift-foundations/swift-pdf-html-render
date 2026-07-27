// PDF.HTML.Configuration.Outline.swift
// Document outline (bookmarks/TOC) configuration

import ISO_32000

extension PDF.HTML.Configuration {
    /// Document outline (bookmarks/TOC) configuration.
    public struct Outline: Sendable, Equatable {
        /// Maximum heading level to expand by default in the document outline.
        ///
        /// Controls which outline items are expanded when the PDF is first opened:
        /// - `1`: Only H1 items expanded (default, shows main chapters)
        /// - `2`: H1 and H2 expanded (shows chapters and sections)
        /// - `6`: All levels expanded
        /// - `0`: All levels collapsed
        public var openToLevel: Int

        /// Default RGB color for outline items (nil uses viewer default, typically black).
        ///
        /// Per PDF spec, this is three numbers in the range 0.0 to 1.0,
        /// representing the components in the DeviceRGB colour space.
        public var color: ISO_32000.DeviceRGB?

        /// Default text style flags for outline items.
        ///
        /// - `.italic`: Display outline text in italic
        /// - `.bold`: Display outline text in bold
        public var flags: ISO_32000.Outline.ItemFlags

        public init(
            openToLevel: Int = 1,
            color: ISO_32000.DeviceRGB? = nil,
            flags: ISO_32000.Outline.ItemFlags = []
        ) {
            self.openToLevel = openToLevel
            self.color = color
            self.flags = flags
        }
    }
}
