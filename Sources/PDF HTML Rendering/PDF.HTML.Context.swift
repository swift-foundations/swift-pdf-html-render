// PDF.HTML.Context.swift
// Combined rendering context for HTML-to-PDF conversion

import Copy_on_Write
public import Dictionary_Primitives
import Rendering_Primitives

// MARK: - Context combining PDF.Context and Configuration

extension PDF.HTML {
    /// Combined context for HTML to PDF rendering.
    ///
    /// This value type bundles `PDF.Context` (mutable layout state) with
    /// `PDF.HTML.Configuration` (immutable rendering settings), providing
    /// a single context parameter for the render method.
    ///
    /// Uses Copy-on-Write (CoW) semantics for efficiency: the struct holds
    /// a reference to storage (8 bytes on stack), and only copies the storage
    /// when mutating a shared instance. This prevents stack overflow while
    /// maintaining value semantics.
    @CoW
    public struct Context {
        /// The mutable PDF layout context (position, font, page state, etc.)
        public var pdf: PDF.Context

        /// The immutable rendering configuration
        public private(set) var configuration: PDF.HTML.Configuration

        /// Active table layout context (nil when not in a table)
        public var table: Context.Table?

        /// HTML attributes for the current element (colspan, rowspan, etc.)
        ///
        /// Populated by `HTML._Attributes` wrapper during rendering.
        /// Used by table cell rendering to extract colspan/rowspan values.
        public var attributes: Dictionary<String, String>.Ordered = .init()

        // MARK: - Link Tracking

        /// Link state: URLs, internal link targets, named destinations.
        public var link: Link = .init()

        // MARK: - Block Flow

        /// Pending bottom margin from previous block element (for margin collapsing).
        public var pendingBottomMargin: PDF.UserSpace.Height = .init(0)

        /// Deferred render closure for keep-with-next behavior (page-break-after: avoid).
        public var deferredKeepWithNextRender: Deferred?

        /// Break flags set by `Style.Context.Modifier.apply(to:)`.
        ///
        /// Callers capture and reset via `captureBreakFlags()`.
        public var avoidPageBreakAfter: Bool = false
        public var forcePageBreakAfter: Bool = false
        public var avoidPageBreakInside: Bool = false

        // MARK: - Speculative Rendering (Keep-With-Next)

        /// Snapshot of context state taken when speculative rendering begins.
        ///
        /// The `@CoW` property wrapper on both `PDF.HTML.Context` and
        /// `PDF.Context` gives cheap snapshots via reference counting.
        /// On rollback, the entire context is restored from the snapshot.
        public var speculativeSnapshot: PDF.HTML.Context?

        /// Actions recorded during speculative rendering for replay after rollback.
        public var speculativeActions: [Rendering.Action]?

        // MARK: - Section Tracking

        /// Section and heading state for headers/footers and bookmarks.
        public var section: Section = .init()

        // MARK: - Rendering.Context Scope Stacks

        /// Element scope stack for push.element/pop.element state save/restore.
        public var elementStack: [Element.Scope] = []

        /// Style scope stack for push.style/pop.style state save/restore.
        public var styleScopeStack: [Style.Snapshot] = []
    }
}

// MARK: - Margin Collapsing

extension PDF.HTML.Context {
    /// Apply collapsed margin between blocks.
    ///
    /// CSS margin collapsing: adjacent vertical margins collapse to the larger value.
    /// This method flushes any pending inline content, applies the effective margin
    /// (max of pending bottom and new top), then stores the new bottom margin.
    ///
    /// - Parameters:
    ///   - topMargin: Top margin of the current element
    ///   - bottomMargin: Bottom margin of the current element (stored for next collapse)
    public mutating func applyCollapsedMargin(
        top topMargin: PDF.UserSpace.Height,
        bottom bottomMargin: PDF.UserSpace.Height
    ) {
        // Flush pending inline content
        if pdf.inline.hasRuns {
            pdf.flush.inline()
        }

        // CSS margin collapse: use larger of adjacent margins
        let collapsedMargin = max(pendingBottomMargin, topMargin)

        // Apply the collapsed margin
        if collapsedMargin > .init(0) {
            pdf.advance(collapsedMargin)
        }

        // Store bottom margin for next collapse
        pendingBottomMargin = bottomMargin
    }

    /// Reset margin collapsing state.
    ///
    /// Call this when starting a new formatting context (e.g., new page,
    /// entering a block formatting context like a table cell).
    public mutating func resetMarginCollapsing() {
        pendingBottomMargin = .init(0)
    }
}

// MARK: - Break Flag Capture

extension PDF.HTML.Context {
    /// Capture and reset all break flags set by style modifiers.
    ///
    /// This centralizes the set-check-reset pattern used after applying
    /// `Style.Context.Modifier` properties.
    public mutating func captureBreakFlags() -> Break {
        let flags = Break(
            avoidAfter: avoidPageBreakAfter,
            forceAfter: forcePageBreakAfter,
            avoidInside: avoidPageBreakInside
        )
        avoidPageBreakAfter = false
        forcePageBreakAfter = false
        avoidPageBreakInside = false
        return flags
    }
}

// MARK: - Scoped Style State

extension PDF.HTML.Context {
    /// Execute a closure with scoped style and box model state.
    ///
    /// Saves style, margins, padding, explicit dimensions, and layout box X bounds
    /// before the closure. Restores them after. Y position is NOT restored — it must
    /// advance through content rendering.
    public mutating func withSavedStyleState(
        _ body: (inout PDF.HTML.Context) -> Void
    ) {
        let snapshot = Style.Snapshot(from: self)
        body(&self)
        snapshot.restore(to: &self)
    }
}

// MARK: - Content Measurement

extension PDF.HTML.Context {
    /// Measure the height that content would occupy without rendering it.
    ///
    /// Creates a temporary context clone, runs the render closure in measurement
    /// mode, and returns the resulting height. The current context is not modified.
    ///
    /// - Parameter render: Closure that renders content into the temporary context.
    /// - Returns: The measured content height.
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
