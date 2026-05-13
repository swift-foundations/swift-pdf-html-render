// PDF.HTML.Context.swift
// Combined rendering context for HTML-to-PDF conversion

import Copy_on_Write
public import Dictionary_Primitives
import Render_Primitives

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

        // MARK: - Post-Push Layout Slots (γ-slots)

        /// Pending table border color set by a post-push_layout CSS modifier
        /// before `_pushElement("table", …)` created `table`.
        ///
        /// Drained at `pushBlockElement` "table" case after `context.table` is
        /// instantiated; cleared on drain. Border-family CSS modifiers write
        /// here when `context.table == nil` at dispatch time.
        public var pendingTableBorderColor: PDF.Color?

        /// Pending table border width set by a post-push_layout CSS modifier
        /// before `_pushElement("table", …)` created `table`.
        public var pendingTableBorderWidth: PDF.UserSpace.Size<1>?

        /// Pending per-side border declarations captured from CSS modifiers
        /// (`border-top`/`border-right`/`border-bottom`/`border-left`) that
        /// fired AFTER `open(.style)` but BEFORE the inner element's
        /// `_pushElement`. Drained into `Element.Scope.pendingBorder*` at
        /// the next `_pushElement`; cleared on drain. Rendered at element
        /// pop time per CSS Backgrounds 3 §3.
        public var pendingSideBorderTop: Element.Scope.PendingSideBorder?
        public var pendingSideBorderRight: Element.Scope.PendingSideBorder?
        public var pendingSideBorderBottom: Element.Scope.PendingSideBorder?
        public var pendingSideBorderLeft: Element.Scope.PendingSideBorder?

        /// True when a `W3C_CSS_BoxModel.Width` modifier fired since the
        /// last element push. Consumed at the next `_pushElement`: if the
        /// element is a `<table>`, the table records `hasExplicitWidth =
        /// true`; otherwise the flag is cleared. Drives the shrink-to-fit
        /// gate in `finalizeFirstRow` per CSS 2.1 §17.5.2.2.
        public var pendingExplicitWidth: Bool = false

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

        /// Break flags set by `Style.Context.Modifier.apply(to:)`.
        ///
        /// Scoped per style level: `_pushStyle` saves and clears these flags,
        /// `_popStyle` processes flags set in that scope, then restores the parent's.
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
        public var speculativeActions: [Render_Primitives.Render.Action]?

        // MARK: - Section Tracking

        /// Section and heading state for headers/footers and bookmarks.
        public var section: Section = .init()

        // MARK: - Render_Primitives.Render.Context Scope Stacks

        /// Element scope stack for push.element/pop.element state save/restore.
        public var elementStack: [Element.Scope] = []

        /// Style scope stack for push.style/pop.style state save/restore.
        public var styleScopeStack: [Style.Snapshot] = []

        // MARK: - Head-Element Text Interception (Phase 1 CSS cascade scaffolding)

        /// True while inside a `<style>` element scope (between matching
        /// `_pushElement`/`_popElement` calls for tagName "style"). `text()`
        /// calls during this scope append to `currentStyleBlockBuffer` for
        /// later CSS parsing instead of rendering as visible PDF text.
        public var insideStyleBlock: Bool = false

        /// Buffer accumulating the current `<style>` element's text content.
        /// Drained into `collectedStyleBlocks` at `_popElement` for the
        /// style tag.
        public var currentStyleBlockBuffer: String = ""

        /// Accumulated `<style>` block contents, one entry per `<style>`
        /// element rendered through `_render`. Phase 1's CSS parser consumes
        /// these to extract type-selector rules (subsequent commit). Order
        /// matches source order, preserving the cascade-source-order
        /// invariant per CSS Cascade §6.4.4.
        public var collectedStyleBlocks: [String] = []

        /// True while inside a `<title>` element scope. `text()` calls during
        /// this scope are silently dropped in Phase 1 — Phase 2 (deferred)
        /// will route title content to `ISO_32000.Document.Info.title`.
        public var insideTitleBlock: Bool = false

        /// Accumulated parsed CSS rules from all `<style>` blocks rendered
        /// so far. Each `<style>` element's contents are parsed at its
        /// `_popElement` and appended here in source order. Phase 1's
        /// `_pushElement` cascade-apply loop iterates this collection to
        /// match type-selector rules against the pushing element's tag.
        public var parsedStylesheet: PDF.HTML.CSS.Stylesheet = PDF.HTML.CSS.Stylesheet()
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
