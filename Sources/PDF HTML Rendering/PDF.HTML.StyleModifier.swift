//
//  File.swift
//  swift-pdf-html-rendering
//
//  Created by Coen ten Thije Boonkkamp on 10/12/2025.
//

import CSS_Standard
import HTML_Renderable
import Layout_Primitives
import PDF_Rendering
import WHATWG_HTML

extension PDF.HTML {
    /// Protocol for CSS properties that can modify PDF rendering context.
    ///
    /// CSS property types conform to this protocol to define how they affect
    /// PDF rendering. This enables the same `.inlineStyle(...)` API used for
    /// HTML to also affect PDF output.
    ///
    /// Example conformance:
    /// ```swift
    /// extension FontWeight: PDF.HTML.StyleModifier {
    ///     public func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration) {
    ///         if self == .bold { context.style.font = context.style.font.bold }
    ///     }
    /// }
    /// ```
    public protocol StyleModifier {
        /// Apply this style to the PDF rendering context.
        func apply(to context: inout PDF.Context, configuration: PDF.HTML.Configuration)
    }

    /// Protocol for CSS properties that need access to the full HTML rendering context.
    ///
    /// Use this for properties like `page-break-after: avoid` that need to affect
    /// the HTML-level rendering state (e.g., deferred content for sticky headers).
    public protocol HTMLContextStyleModifier {
        /// Apply this style to the HTML rendering context.
        func apply(to context: inout PDF.HTML.Context)
    }
}


// MARK: - Tag Renderer Protocol (Internal)

extension PDF.HTML {
    /// Internal protocol for tags that provide intrinsic PDF styling.
    ///
    /// Tags conform to this to define intrinsic style changes (font, size, color)
    /// that mirror browser user-agent stylesheets. For example, `<h1>` is bold
    /// and 2em size, `<em>` is italic.
    ///
    /// The save/restore of style state is handled by HTML.Element.
    internal protocol TagRenderer {
        /// Apply tag-specific styling to the context.
        static func applyStyle(to context: inout PDF.Context, configuration: PDF.HTML.Configuration)
    }

    /// Protocol for list container tags (ul, ol) that manage list context.
    internal protocol ListContainer {
        /// Get the list type for this container.
        static func listType() -> PDF.Context.ListType
    }

    /// Protocol for list item tags that render markers.
    internal protocol ListItemRenderer {
        /// Render the list marker and return the marker width.
        static func renderMarker(
            context: inout PDF.Context,
            configuration: PDF.HTML.Configuration
        ) -> PDF.UserSpace.Width
    }

    // MARK: - Block Element Margins Protocol

    /// Protocol for block elements that have intrinsic margins (like WebKit UA stylesheet).
    ///
    /// Block elements like headings, paragraphs, lists have default top/bottom margins.
    /// These margins are applied before/after the element content.
    internal protocol BlockMargins {
        /// Top margin using CSS length/percentage
        static var marginTop: LengthPercentage { get }
        /// Bottom margin using CSS length/percentage
        static var marginBottom: LengthPercentage { get }
    }

    // MARK: - Void Element Protocol

    /// Protocol for void element tags (br, hr, img, etc.) that have no content.
    ///
    /// Unlike `TagRenderer` which modifies styling for content, void elements
    /// perform their action directly without rendering any child content.
    internal protocol VoidElementRenderer {
        /// Render this void element's effect (e.g., line break, horizontal rule).
        static func render(context: inout PDF.HTML.Context)
    }
}
