// PDF.HTML+DynamicDispatchProtocols.swift
// Package protocols enabling dynamic dispatch for result builder types

import Dictionary_Primitives
import HTML_Renderable

// MARK: - Dynamic Dispatch Support Protocols

/// Internal protocol to enable dynamic dispatch for _Tuple without variadic constraints.
///
/// This works around Swift's limitation where runtime existential casts (`as? any Protocol`)
/// don't work correctly for conditional conformances on variadic generics.
package protocol _TupleContent {
    /// Render each element of the tuple using dynamic dispatch.
    func _renderEachElementDynamically(context: inout PDF.HTML.Context)
    /// Collect each element of the tuple into a flat collection for iterative rendering.
    func _collectElements(into collection: inout [Any])
}

/// Marker protocol for HTML.Element.Tag dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `HTML.Element.Tag: PDF.HTML.View where Content: PDF.HTML.View`.
package protocol _HTMLElementContent {
    /// Render this element using dynamic dispatch for content.
    func _renderElementDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for HTML.Raw (renders as empty in PDF context).
///
/// Raw HTML content (like `<script>...</script>`) doesn't have a meaningful
/// PDF representation and is safely ignored during PDF rendering.
package protocol _HTMLRawContent {}

/// Marker protocol for HTML.Styled dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `HTML.Styled: PDF.HTML.View where Content: PDF.HTML.View`.
package protocol _HTMLStyledContent {
    /// Render this styled content using dynamic dispatch for the wrapped content.
    func _renderStyledDynamically(context: inout PDF.HTML.Context)

    /// The CSS property to apply (may be nil).
    var styledProperty: Any? { get }

    /// Apply this styled element's property to the context.
    /// Returns flags for break handling.
    func applyStyle(to context: inout PDF.HTML.Context) -> (avoidBreakAfter: Bool, forceBreakAfter: Bool, avoidBreakInside: Bool)

    /// Get the wrapped content as _HTMLStyledContent if it is one (avoids existential boxing).
    var wrappedStyledContent: (any _HTMLStyledContent)? { get }

    /// Render the wrapped content directly (avoids existential boxing of content).
    func renderWrappedContent(context: inout PDF.HTML.Context)
}

/// Marker protocol for _Conditional dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `_Conditional: PDF.HTML.View where First: PDF.HTML.View, Second: PDF.HTML.View`.
package protocol _ConditionalContent {
    /// Render the active branch of this conditional using dynamic dispatch.
    func _renderConditionalDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for _Array dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `_Array: PDF.HTML.View where Element: PDF.HTML.View`.
package protocol _ArrayContent {
    /// Render all elements in the array using dynamic dispatch.
    func _renderArrayDynamically(context: inout PDF.HTML.Context)
}

/// Marker protocol for Optional dynamic dispatch.
///
/// Works around Swift's limitation where `as? any PDF.HTML.View` fails for
/// conditional conformances like `Optional: PDF.HTML.View where Wrapped: PDF.HTML.View`.
package protocol _OptionalContent {
    /// Render the optional's wrapped value if present, using dynamic dispatch.
    func _renderOptionalDynamically(context: inout PDF.HTML.Context)
}
