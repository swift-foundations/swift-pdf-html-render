// PDF.HTML.Context.swift
// Combined rendering context for HTML-to-PDF conversion

import Copy_on_Write
public import Dictionary_Primitives

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
        public var deferredKeepWithNextRender: DeferredRender?

        /// Break flags set by `HTMLContextStyleModifier.apply(to:)`.
        ///
        /// Callers capture and reset via `captureBreakFlags()`.
        public var avoidPageBreakAfter: Bool = false
        public var forcePageBreakAfter: Bool = false
        public var avoidPageBreakInside: Bool = false

        // MARK: - Section Tracking

        /// Section and heading state for headers/footers and bookmarks.
        public var section: Section = .init()
    }
}

// MARK: - Link Sub-Context

extension PDF.HTML.Context {
    /// Grouped link tracking state.
    public struct Link: Sendable {
        /// Current link URL for text being rendered inside an anchor element.
        public var currentURL: String?

        /// Current internal link target ID (without # prefix).
        public var currentInternalId: String?

        /// Named destinations for internal links (id -> page/position).
        public var destinations: [String: Destination] = [:]

        /// Pending internal links to resolve after rendering.
        public var pending: [Pending] = []

        public init() {}
    }
}

extension PDF.HTML.Context.Link {
    /// Information about a named destination (anchor target).
    public struct Destination: Sendable {
        public let pageNumber: Int
        public let yPosition: PDF.UserSpace.Y

        public init(pageNumber: Int, yPosition: PDF.UserSpace.Y) {
            self.pageNumber = pageNumber
            self.yPosition = yPosition
        }
    }

    /// A pending internal link that needs to be resolved.
    public struct Pending: Sendable {
        public let targetId: String
        public let pageNumber: Int
        public let bounds: PDF.UserSpace.Rectangle

        public init(targetId: String, pageNumber: Int, bounds: PDF.UserSpace.Rectangle) {
            self.targetId = targetId
            self.pageNumber = pageNumber
            self.bounds = bounds
        }
    }
}

// MARK: - Section Sub-Context

extension PDF.HTML.Context {
    /// Grouped section and heading tracking state.
    public struct Section: Sendable {
        /// Current section title (from most recent H1-H3 heading).
        public var currentTitle: String?

        /// Section titles at the start of each page (page number -> title).
        public var pageTitles: [Int: String] = [:]

        /// Collected heading entries for bookmark generation.
        public var headings: [HeadingEntry] = []

        public init() {}
    }
}

extension PDF.HTML.Context.Section {
    /// Entry for a heading collected during rendering.
    public struct HeadingEntry: Sendable {
        public let level: Int
        public let text: String
        public let pageNumber: Int
        public let yPosition: PDF.UserSpace.Y

        public init(level: Int, text: String, pageNumber: Int, yPosition: PDF.UserSpace.Y) {
            self.level = level
            self.text = text
            self.pageNumber = pageNumber
            self.yPosition = yPosition
        }
    }
}

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
        if pdf.hasInlineRuns {
            pdf.flushInlineRuns()
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

extension PDF.HTML.Context {
    /// Snapshot of PDF context state for restoration during deferred rendering
    ///
    /// **Important**: Only captures and restores **style** (font, color, etc.),
    /// NOT the layout position. The deferred content should render at the
    /// current Y position when the closure executes, not where the header
    /// was originally encountered.
    public struct Snapshot: Sendable {
        public let style: PDF.Context.Style.Resolved

        public init(from context: PDF.Context) {
            self.style = context.style
        }

        public func restore(to context: inout PDF.Context) {
            context.style = style
            // NOTE: Do NOT restore layoutBox - the deferred content should
            // render at the current position, not the original position
        }
    }

}
extension PDF.HTML.Context {
    /// Deferred render operation for sticky headers
    public struct DeferredRender: @unchecked Sendable {
        /// Closure that renders the deferred content
        ///
        /// Note: Not marked @Sendable because rendering is single-threaded and synchronous.
        /// The closure captures generic view types that aren't Sendable.
        public let render: (inout PDF.HTML.Context) -> Void
        /// Measured height of the deferred content
        public let measuredHeight: PDF.UserSpace.Height
    }

}

// MARK: - Break Flag Capture

extension PDF.HTML.Context {
    /// Captured break flags from style modifier application.
    ///
    /// Style modifiers communicate break intent by setting flags on the context.
    /// `captureBreakFlags()` atomically reads and resets them, returning this value.
    public struct BreakFlags: Sendable {
        public var avoidAfter: Bool
        public var forceAfter: Bool
        public var avoidInside: Bool

        public static let none = BreakFlags(avoidAfter: false, forceAfter: false, avoidInside: false)
    }

    /// Capture and reset all break flags set by style modifiers.
    ///
    /// This centralizes the set-check-reset pattern used after applying
    /// `HTMLContextStyleModifier` properties.
    public mutating func captureBreakFlags() -> BreakFlags {
        let flags = BreakFlags(
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
        let savedStyle = pdf.style
        let savedMarginTop = pdf.marginTop
        let savedMarginRight = pdf.marginRight
        let savedMarginBottom = pdf.marginBottom
        let savedMarginLeft = pdf.marginLeft
        let savedPaddingTop = pdf.paddingTop
        let savedPaddingRight = pdf.paddingRight
        let savedPaddingBottom = pdf.paddingBottom
        let savedPaddingLeft = pdf.paddingLeft
        let savedExplicitWidth = pdf.explicitWidth
        let savedExplicitHeight = pdf.explicitHeight
        let savedLayoutBox = pdf.layoutBox

        body(&self)

        pdf.style = savedStyle
        pdf.marginTop = savedMarginTop
        pdf.marginRight = savedMarginRight
        pdf.marginBottom = savedMarginBottom
        pdf.marginLeft = savedMarginLeft
        pdf.paddingTop = savedPaddingTop
        pdf.paddingRight = savedPaddingRight
        pdf.paddingBottom = savedPaddingBottom
        pdf.paddingLeft = savedPaddingLeft
        pdf.explicitWidth = savedExplicitWidth
        pdf.explicitHeight = savedExplicitHeight
        // Y position advances through content — only restore X bounds
        pdf.layoutBox.llx = savedLayoutBox.llx
        pdf.layoutBox.urx = savedLayoutBox.urx
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
