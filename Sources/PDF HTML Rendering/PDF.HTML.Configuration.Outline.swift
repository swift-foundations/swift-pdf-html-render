import ISO_32000

extension PDF.HTML.Configuration {

    public struct Outline: Sendable, Equatable {

        public var openToLevel: Int

        public var color: ISO_32000.DeviceRGB?

        public var flags: ISO_32000.Outline.ItemOptions

        public init(
            openToLevel: Int = 1,
            color: ISO_32000.DeviceRGB? = nil,
            flags: ISO_32000.Outline.ItemOptions = []
        ) {
            self.openToLevel = openToLevel
            self.color = color
            self.flags = flags
        }
    }
}
