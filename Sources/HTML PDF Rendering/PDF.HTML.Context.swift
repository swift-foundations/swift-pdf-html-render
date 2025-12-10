//
//  File.swift
//  swift-pdf-html-rendering
//
//  Created by Coen ten Thije Boonkkamp on 10/12/2025.
//

// MARK: - Context combining PDF.Context and Configuration

extension PDF.HTML {
    /// Combined context for HTML to PDF rendering.
    ///
    /// This product type bundles `PDF.Context` (mutable layout state) with
    /// `PDF.HTML.Configuration` (immutable rendering settings), providing
    /// a single context parameter for the render method.
    public struct Context {
        /// The mutable PDF layout context (position, font, page state, etc.)
        public var pdf: PDF.Context

        /// The immutable rendering configuration
        public let configuration: PDF.HTML.Configuration

        /// Active table layout context (nil when not in a table)
        public var tableContext: Context.Table?

        /// HTML attributes for the current element (colspan, rowspan, etc.)
        ///
        /// Populated by `HTML._Attributes` wrapper during rendering.
        /// Used by table cell rendering to extract colspan/rowspan values.
        public var attributes: OrderedDictionary<String, String> = [:]

        /// Current link URL for text being rendered inside an anchor element.
        ///
        /// Set by `Anchor+PDF.HTML.View` when rendering anchor content.
        /// Used by `String+PDF.HTML.View` to pass URL to TextRun for PDF annotations.
        public var currentLinkURL: String?

        /// Pending bottom margin from previous block element (for margin collapsing).
        ///
        /// In CSS, adjacent vertical margins collapse - only the larger margin is used.
        /// This tracks the bottom margin of the previous block element so it can be
        /// collapsed with the top margin of the next block element.
        public var pendingBottomMargin: PDF.UserSpace.Unit = 0

        /// Deferred render closure for keep-with-next behavior (page-break-after: avoid).
        ///
        /// When an element with `page-break-after: avoid` is encountered, instead of
        /// rendering immediately, we store a closure that will render the element.
        /// When the next block element is rendered, we check if the deferred header
        /// plus at least one line of content fits on the current page. If not, we
        /// start a new page before rendering the deferred content.
        public var deferredKeepWithNextRender: DeferredRender?

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

        /// Snapshot of PDF context state for restoration during deferred rendering
        ///
        /// **Important**: Only captures and restores **style** (font, color, etc.),
        /// NOT the layout position. The deferred content should render at the
        /// current Y position when the closure executes, not where the header
        /// was originally encountered.
        public struct PDFContextSnapshot: Sendable {
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

        /// Flag indicating the current element should avoid page break after it.
        /// Set by `page-break-after: avoid` CSS property.
        public var avoidPageBreakAfter: Bool = false

        public init(pdf: PDF.Context, configuration: PDF.HTML.Configuration) {
            self.pdf = pdf
            self.configuration = configuration
            self.tableContext = nil
            self.pendingBottomMargin = 0
            self.deferredKeepWithNextRender = nil
            self.avoidPageBreakAfter = false
        }

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
            top topMargin: PDF.UserSpace.Unit,
            bottom bottomMargin: PDF.UserSpace.Unit
        ) {
            // Flush pending inline content
            if pdf.hasInlineRuns {
                pdf.flushInlineRuns()
            }

            // CSS margin collapse: use larger of adjacent margins
            let collapsedMargin = max(pendingBottomMargin, topMargin)

            // Apply the collapsed margin
            if collapsedMargin > 0 {
                pdf.advance(PDF.UserSpace.Y(collapsedMargin))
            }

            // Store bottom margin for next collapse
            pendingBottomMargin = bottomMargin
        }

        /// Reset margin collapsing state.
        ///
        /// Call this when starting a new formatting context (e.g., new page,
        /// entering a block formatting context like a table cell).
        public mutating func resetMarginCollapsing() {
            pendingBottomMargin = 0
        }
    }
}
