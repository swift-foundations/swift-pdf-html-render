extension PDF.HTML.Context {

    public struct Snapshot: Sendable {
        public let style: PDF.Context.Style.Resolved

        public init(from context: PDF.Context) {
            self.style = context.style
        }
    }
}

extension PDF.HTML.Context.Snapshot {
    public func restore(to context: inout PDF.Context) {
        context.style = style

    }
}
