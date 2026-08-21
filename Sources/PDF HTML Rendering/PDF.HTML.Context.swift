public import Buffer_Linear_Primitive
import Column_Primitives
import Copy_on_Write
public import Dictionary_Ordered_Primitives
import Dictionary_Primitives
public import HTML_Rendering_Core
import Hash_Indexed_Primitive
import Hash_Primitives
import Ownership_Shared_Primitive
import Render_Primitives

extension PDF.HTML {

    @CoW
    public struct Context {

        public var pdf: PDF.Context

        public private(set) var configuration: PDF.HTML.Configuration

        public var table: Context.Table?

        public var pendingTableBorderColor: PDF.Color?

        public var pendingTableBorderWidth: PDF.UserSpace.Size<1>?

        public var pendingSideBorderTop: Element.Scope.PendingSideBorder?
        public var pendingSideBorderRight: Element.Scope.PendingSideBorder?
        public var pendingSideBorderBottom: Element.Scope.PendingSideBorder?
        public var pendingSideBorderLeft: Element.Scope.PendingSideBorder?

        public var pendingExplicitWidth: Bool = false

        public var attributes: HTML.Context.Attributes = .init()

        public var link: Link = .init()

        public var pendingBottomMargin: PDF.UserSpace.Height = .init(0)

        public var avoidPageBreakAfter: Bool = false
        public var forcePageBreakAfter: Bool = false
        public var avoidPageBreakInside: Bool = false

        public var speculativeSnapshot: PDF.HTML.Context?

        public var speculativeActions: [Render_Primitives.Render.Action]?

        public var section: Section = .init()

        public var elementStack: [Element.Scope] = []

        public var styleScopeStack: [Style.Snapshot] = []

        public var insideStyleBlock: Bool = false

        public var currentStyleBlockBuffer: String = ""

        public var collectedStyleBlocks: [String] = []

        public var insideTitleBlock: Bool = false

        public var parsedStylesheet: PDF.HTML.CSS.Stylesheet = PDF.HTML.CSS.Stylesheet()
    }
}

extension PDF.HTML.Context {

    public mutating func applyCollapsedMargin(
        top topMargin: PDF.UserSpace.Height,
        bottom bottomMargin: PDF.UserSpace.Height
    ) {

        if pdf.inline.hasRuns {
            pdf.flush.inline()
        }

        let collapsedMargin = max(pendingBottomMargin, topMargin)

        if collapsedMargin > .init(0) {
            pdf.advance(collapsedMargin)
        }

        pendingBottomMargin = bottomMargin
    }

    public mutating func resetMarginCollapsing() {
        pendingBottomMargin = .init(0)
    }
}

extension PDF.HTML.Context {

    public mutating func withSavedStyleState(
        _ body: (inout PDF.HTML.Context) -> Void
    ) {
        let snapshot = Style.Snapshot(from: self)
        body(&self)
        snapshot.restore(to: &self)
    }
}

extension PDF.HTML.Context {

    public mutating func measureContentHeight(
        _ render: (inout PDF.HTML.Context) -> Void
    ) -> PDF.UserSpace.Height {
        let snapshot = Snapshot(from: pdf)
        let configuration = configuration
        let pendingBottomMargin = pendingBottomMargin

        return pdf.measure { measureContext in
            var tempContext = PDF.HTML.Context(pdf: measureContext, configuration: configuration)
            tempContext.pendingBottomMargin = pendingBottomMargin
            snapshot.restore(to: &tempContext.pdf)
            render(&tempContext)
            tempContext.pdf.flush.inline()
            measureContext.layout.box.lly = tempContext.pdf.layout.box.lly
        }
    }
}

extension PDF.HTML.Context {
    public mutating func with<T>(
        _ keyPath: WritableKeyPath<PDF.HTML.Context, T>,
        _ body: (inout T) -> Void
    ) {
        var value = self[keyPath: keyPath]
        body(&value)
        self[keyPath: keyPath] = value
    }
}

extension PDF.HTML.Context {
    public mutating func with<T>(
        _ keyPath: WritableKeyPath<PDF.HTML.Context, T?>,
        _ body: (inout T) -> Void
    ) {
        guard var value = self[keyPath: keyPath] else { return }
        body(&value)
        self[keyPath: keyPath] = value
    }
}
