// PDF.HTML.Render.swift
// Block and inline rendering helpers for static and dynamic dispatch paths

import HTML_Renderable
import PDF_Rendering

extension PDF.HTML {
    /// Namespace for block and inline rendering dispatch.
    public enum Render {
        /// Render content as a block element (flushes inline runs before and after).
        @inlinable
        public static func block<C: PDF.HTML.View>(
            _ content: C?,
            context: inout PDF.HTML.Context,
            beforeSpacing: PDF.UserSpace.Height = .init(0),
            afterSpacing: PDF.UserSpace.Height = .init(0)
        ) {
            if context.pdf.hasInlineRuns {
                context.pdf.flushInlineRuns()
            }

            if beforeSpacing > .init(0) {
                context.pdf.advance(beforeSpacing)
            }

            if let content {
                C._render(content, context: &context)
            }

            if context.pdf.hasInlineRuns {
                context.pdf.flushInlineRuns()
            }

            if afterSpacing > .init(0) {
                context.pdf.advance(afterSpacing)
            }
        }

        /// Render content inline (no flush).
        @inlinable
        public static func inline<C: PDF.HTML.View>(
            _ content: C?,
            context: inout PDF.HTML.Context
        ) {
            if let content {
                C._render(content, context: &context)
            }
        }

        // MARK: - Dynamic Dispatch

        /// Dynamic dispatch variants for content known only as `HTML.View`.
        public enum Dynamic {
            /// Render content as a block element using dynamic dispatch.
            ///
            /// Use when the content type conforms to `HTML.View` but not
            /// necessarily `PDF.HTML.View`.
            public static func block(
                _ content: some HTML.View,
                context: inout PDF.HTML.Context
            ) {
                if context.pdf.hasInlineRuns {
                    context.pdf.flushInlineRuns()
                }

                PDF.HTML.renderHTMLView(content, context: &context)

                if context.pdf.hasInlineRuns {
                    context.pdf.flushInlineRuns()
                }
            }

            /// Render content inline using dynamic dispatch.
            ///
            /// Use when the content type conforms to `HTML.View` but not
            /// necessarily `PDF.HTML.View`.
            public static func inline(
                _ content: some HTML.View,
                context: inout PDF.HTML.Context
            ) {
                PDF.HTML.renderHTMLView(content, context: &context)
            }
        }
    }
}
