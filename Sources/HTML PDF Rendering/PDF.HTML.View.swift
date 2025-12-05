// PDF.HTML.View.swift
// Static dispatch PDF rendering for HTML.View types

import HTML_Renderable
import PDF_Rendering
import Renderable

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
        public var tableContext: TableContext?

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
            public let render: (inout [PDF.Render.Operation], inout PDF.HTML.Context) -> Void
            /// Measured height of the deferred content
            public let measuredHeight: PDF.UserSpace.Height
        }

        /// Snapshot of PDF context state for restoration during deferred rendering
        public struct PDFContextSnapshot: Sendable {
            public let font: PDF.Font
            public let fontSize: PDF.UserSpace.Unit
            public let color: PDF.Color
            public let textDecoration: PDF.TextDecoration
            public let textBackgroundColor: PDF.Color?
            public let x: PDF.UserSpace.X
            public let availableWidth: PDF.UserSpace.Width

            public init(from context: PDF.Context) {
                self.font = context.font
                self.fontSize = context.fontSize
                self.color = context.color
                self.textDecoration = context.textDecoration
                self.textBackgroundColor = context.textBackgroundColor
                self.x = context.x
                self.availableWidth = context.availableWidth
            }

            public func restore(to context: inout PDF.Context) {
                context.font = font
                context.fontSize = fontSize
                context.color = color
                context.textDecoration = textDecoration
                context.textBackgroundColor = textBackgroundColor
                context.x = x
                context.availableWidth = availableWidth
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
        /// This method applies the effective margin (max of pending bottom and new top),
        /// then stores the new bottom margin for the next element.
        ///
        /// - Parameters:
        ///   - topMargin: Top margin of the current element
        ///   - bottomMargin: Bottom margin of the current element (stored for next collapse)
        public mutating func applyCollapsedMargin(top topMargin: PDF.UserSpace.Unit, bottom bottomMargin: PDF.UserSpace.Unit) {
            // Collapse: use max of pending bottom margin and current top margin
            let collapsedMargin = max(pendingBottomMargin, topMargin)

            // Apply the collapsed margin (only if there's something to apply)
            if collapsedMargin > 0 {
                pdf.advance(PDF.UserSpace.Y(collapsedMargin))
            }

            // Store the bottom margin for collapsing with next element
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

// MARK: - Table Layout Support

extension PDF.HTML {
    /// Context for table layout
    public struct TableContext {
        /// X position where the table starts
        public var tableX: PDF.UserSpace.X

        /// Total width available for the table
        public var tableWidth: PDF.UserSpace.Width

        /// Number of columns (determined from first row)
        public var columnCount: Int

        /// Width of each column (equal distribution)
        public var columnWidth: PDF.UserSpace.Width {
            guard columnCount > 0 else { return tableWidth }
            return PDF.UserSpace.Width(tableWidth.value / PDF.UserSpace.Unit(columnCount))
        }

        /// Current column index (0-based)
        public var currentColumn: Int

        /// Y position of current row start
        public var rowY: PDF.UserSpace.Y

        /// Cell padding
        public var cellPadding: PDF.UserSpace.Unit

        public init(
            tableX: PDF.UserSpace.X,
            tableWidth: PDF.UserSpace.Width,
            columnCount: Int = 3,
            cellPadding: PDF.UserSpace.Unit = 4
        ) {
            self.tableX = tableX
            self.tableWidth = tableWidth
            self.columnCount = columnCount
            self.currentColumn = 0
            self.rowY = 0
            self.cellPadding = cellPadding
        }

        /// Get X position for current column
        public func xForColumn(_ column: Int) -> PDF.UserSpace.X {
            PDF.UserSpace.X(tableX.value + columnWidth.value * PDF.UserSpace.Unit(column))
        }

        /// Get available width for a cell (column width minus padding)
        public var cellWidth: PDF.UserSpace.Width {
            PDF.UserSpace.Width(columnWidth.value - cellPadding * 2)
        }
    }
}

// MARK: - PDF.HTML.View Protocol

extension PDF.HTML {
    /// Protocol for types that can be rendered to PDF content operations.
    ///
    /// This protocol enables static dispatch for HTML to PDF rendering,
    /// following the same buffer-based pattern as `HTML.View` and `PDF.View`.
    ///
    /// Note: This protocol does NOT extend `Renderable` because HTML types
    /// already conform to `Renderable` via `HTML.View` with different associated
    /// types (`Context == HTML.Context`, `Output == UInt8`). Having two different
    /// `Renderable` conformances would cause a conflict.
    public protocol View {
        /// Render this view to PDF content operations.
        ///
        /// - Parameters:
        ///   - view: The view to render
        ///   - buffer: Buffer to append PDF operations to
        ///   - context: Combined context with PDF layout state and configuration
        static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.HTML.Context
        ) where Buffer.Element == PDF.Render.Operation
    }
}

// MARK: - Default Implementation for HTML.View types

extension PDF.HTML.View where Self: HTML.View, Self.Content: PDF.HTML.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.HTML.Context
    ) where Buffer.Element == PDF.Render.Operation {
        Self.Content._render(view.body, into: &buffer, context: &context)
    }
}
