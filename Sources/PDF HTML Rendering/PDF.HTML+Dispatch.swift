// PDF.HTML+Dispatch.swift
// Worklist-based iterative dispatch and Mirror-based type detection

import CSS_Standard
import Dictionary_Primitives
import HTML_Renderable
import PDF_Rendering
import PDF_Standard
import Rendering_Primitives
import Stack_Primitives
import W3C_CSS_Shared

// MARK: - Dynamic Dispatch Entry Point

extension PDF.HTML {
    /// Dynamic dispatch entry point for rendering any HTML.View to PDF.
    ///
    /// Delegates to `iterativeDispatch` — the worklist-based interpreter that
    /// replaces the former mutual recursion between `renderHTMLView` and
    /// `renderInnerContent`.
    public static func renderHTMLView(
        _ view: some HTML.View,
        context: inout PDF.HTML.Context
    ) {
        iterativeDispatch(view, context: &context)
    }

    // MARK: - Worklist Interpreter

    /// Defunctionalized dispatch continuations.
    ///
    /// Each case is an instruction to the dispatch loop. The rendering pipeline's
    /// recursive calls are replaced by work items on an explicit worklist,
    /// following the `Tree.N.forEachPreOrder` pattern from `swift-tree-primitives`:
    /// push children in reverse order onto a `Stack`, process iteratively.
    ///
    /// Style/attribute save/restore follows the `Tree.N.removeSubtree` pattern:
    /// push `.restoreStyle`/`.restoreAttributes` before `.render(content)`.
    /// LIFO ordering guarantees content renders first, then the restore fires —
    /// equivalent to `defer`.
    private enum Dispatch {
        /// Process a value through the type detection pipeline.
        ///
        /// Replaces recursive calls to `renderHTMLView` and `renderInnerContent`.
        case render(Any)

        /// Post-visit: restore style state after children have rendered.
        ///
        /// Equivalent of `defer { context.pdf.style = saved }` in the former
        /// `renderStyledViaMirror`. Pushed BEFORE `.render(content)` — LIFO
        /// ensures content renders first.
        case restoreStyle(ISO_32000.Context.Style.Resolved)

        /// Post-visit: restore attribute scope after children have rendered.
        ///
        /// Fixes a pre-existing bug where `renderAttributesViaMirror` discarded
        /// HTML attributes (href, id, colspan, rowspan) that `Tag._render` reads.
        /// Reproduces the static path's save/merge/render/restore semantics.
        case restoreAttributes(Dictionary<String, String>.Ordered)

        /// Post-visit: force a page break after content has rendered.
        ///
        /// Reproduces the static path's `forcePageBreakAfter` handling from
        /// `HTML.Styled._render` (line 190-193). The flag is set by
        /// `PageBreakAfter` / `BreakAfter` style modifiers via
        /// `applyStylePropertyViaMirror`, captured during Styled layer peeling,
        /// and deferred until after content renders via LIFO ordering.
        case forcePageBreak
    }

    /// Iterative dispatch loop for the dynamic rendering pipeline.
    ///
    /// Replaces the mutual recursion between `renderHTMLView` and
    /// `renderInnerContent` with a single `Stack<Dispatch>` worklist,
    /// following the `Tree.N.forEachPreOrder` pattern from `swift-tree-primitives`.
    ///
    /// ## What becomes iterative
    ///
    /// | Recursion axis | Mechanism |
    /// |---|---|
    /// | Custom view body chain (`A → A.body → B → B.body`) | `.render(body)` pushed, loop continues |
    /// | Tuple children | Children pushed as `.render` items (absorbs `renderTupleIteratively`) |
    /// | CSS wrapper unwrapping | Extract base, push `.render(base)` |
    /// | `_Attributes` wrapper unwrapping | Save/merge/push `.restoreAttributes` + `.render(content)` |
    /// | `_Conditional` case extraction | Extract active case, push `.render(case)` |
    /// | `Optional` unwrapping | Extract `.some` value, push `.render(someValue)` |
    /// | Styled layer peeling | Save style, peel layers, push `.restoreStyle` then `.render(unwrapped)` |
    ///
    /// ## What stays recursive (bounded)
    ///
    /// `Tag._render` and `_renderElementDynamically` are **terminal operations** from
    /// the worklist's perspective. They handle their own children with their own `defer`
    /// blocks. When they call `Render.Dynamic.block` → `renderHTMLView`, a new worklist
    /// instance is created. This re-entry is bounded by HTML Tag element nesting depth,
    /// not by wrapper-chain depth or custom-view body expansion.
    private static func iterativeDispatch(
        _ initial: Any,
        context: inout PDF.HTML.Context
    ) {
        var worklist = Stack<Dispatch>()
        worklist.push(.render(initial))

        while let item = worklist.pop() {
            switch item {
            case .restoreStyle(let saved):
                context.pdf.style = saved

            case .restoreAttributes(let saved):
                context.attributes = saved

            case .forcePageBreak:
                context.pdf.flush.inline()
                context.pdf.page.new()

            case .render(let value):
                // Phase 0: Tuple — push children (absorbs renderTupleIteratively)
                if let tuple = value as? any Rendering._TupleMarker {
                    var elements: [Any] = []
                    tuple._collectElements(into: &elements)
                    // Push reversed for left-to-right processing (LIFO)
                    for element in elements.reversed() {
                        worklist.push(.render(element))
                    }
                    continue
                }

                // Phase 1: Mirror-based wrapper detection
                //
                // Mirror is allocated in this scope and freed at the end of
                // the switch case — before the next iteration. This replaces
                // the @inline(never) extraction functions (_renderWrapperIfDetected,
                // _renderInnerWrapperIfDetected) which existed solely to free
                // Mirror stack space before recursive calls.
                let mirror = Mirror(reflecting: value)

                if isStyledType(mirror) {
                    let savedStyle = context.pdf.style

                    // Peel consecutive Styled layers iteratively
                    var current = value
                    while true {
                        let m = Mirror(reflecting: current)
                        guard isStyledType(m) else { break }

                        var content: Any?
                        var property: Any?
                        for child in m.children {
                            switch child.label {
                            case "content": content = child.value
                            case "property": property = child.value
                            default: break
                            }
                        }

                        if let prop = property {
                            applyStylePropertyViaMirror(prop, context: &context)
                        }

                        guard let c = content else { break }
                        current = c
                    }

                    let breakFlags = context.captureBreakFlags()

                    // Post-visit: push in LIFO order —
                    // restore runs last, page break fires after content, content renders first
                    worklist.push(.restoreStyle(savedStyle))
                    if breakFlags.forceAfter {
                        worklist.push(.forcePageBreak)
                    }
                    worklist.push(.render(current))
                    continue
                }

                if isCSSWrapperType(mirror) {
                    for child in mirror.children {
                        if child.label == "base" {
                            worklist.push(.render(child.value))
                            break
                        }
                    }
                    continue
                }

                if isAttributesType(mirror) {
                    let savedAttributes = context.attributes

                    // Peel consecutive _Attributes layers iteratively,
                    // merging attributes at each layer. Reproduces the
                    // static path's save/merge/render/restore semantics.
                    var current = value
                    while true {
                        let m = Mirror(reflecting: current)
                        guard isAttributesType(m) else { break }

                        var contentValue: Any?
                        for child in m.children {
                            if child.label == "attributes",
                               let attrs = child.value as? [String: String] {
                                context.attributes.merge.keep.last(
                                    attrs.lazy.map { ($0.key, $0.value) }
                                )
                            }
                            if child.label == "content" {
                                contentValue = child.value
                            }
                        }

                        guard let c = contentValue else { break }
                        current = c
                    }

                    // Post-visit: push restore BEFORE content (LIFO)
                    worklist.push(.restoreAttributes(savedAttributes))
                    worklist.push(.render(current))
                    continue
                }

                if isConditionalType(mirror) {
                    for child in mirror.children {
                        if child.label == "first" || child.label == "second" {
                            worklist.push(.render(child.value))
                            break
                        }
                    }
                    continue
                }

                if isOptionalType(mirror) {
                    for child in mirror.children {
                        if child.label == "some" {
                            worklist.push(.render(child.value))
                            break
                        }
                    }
                    continue // .none → nothing pushed → nothing rendered
                }

                // Phase 2: as? casts (safe — wrappers filtered by Phase 1)
                //
                // These are terminal operations — they call _render directly.

                if let str = value as? String {
                    String._render(str, context: &context)
                    continue
                }

                if let anyView = value as? any _AnyViewContent {
                    anyView._renderAnyViewDynamically(context: &context)
                    continue
                }

                if let pdfView = value as? any PDF.HTML.View {
                    func render<V: PDF.HTML.View>(_ v: V) {
                        V._render(v, context: &context)
                    }
                    render(pdfView)
                    continue
                }

                if let element = value as? any _HTMLElementContent {
                    element._renderElementDynamically(context: &context)
                    continue
                }

                if value is any _HTMLRawContent {
                    continue
                }

                // _ConditionalContent and _OptionalContent Phase 2 casts removed:
                // Phase 1 Mirror detection (isConditionalType, isOptionalType) catches
                // all conditionals and optionals before Phase 2 is reached.

                if let array = value as? any _ArrayContent {
                    array._renderArrayDynamically(context: &context)
                    continue
                }

                // Fallback: custom HTML.View — push body (LOOP, not recurse)
                if let htmlView = value as? any HTML.View {
                    func pushBody<V: HTML.View>(_ v: V) {
                        worklist.push(.render(v.body as Any))
                    }
                    pushBody(htmlView)
                    continue
                }
            }
        }
    }
}

// MARK: - Protocol-Based Styled Rendering (Static Dispatch Path)

extension PDF.HTML {
    /// Render HTML.Styled content by flattening consecutive styled layers iteratively.
    ///
    /// This avoids stack overflow from deeply nested HTML.Styled wrappers (common in VStack
    /// and other components that chain CSS properties like `.css.alignItems().display().flexDirection()`).
    ///
    /// Instead of:
    /// ```
    /// Styled1._render -> renderHTMLView(Styled2) -> Styled2._render -> renderHTMLView(Styled3) -> ...
    /// ```
    ///
    /// We iterate through all nested Styled layers, apply styles, then render the innermost content:
    /// ```
    /// flatten: [Styled1, Styled2, Styled3, ...]
    /// apply all styles
    /// render innermost content
    /// ```
    static func renderFlattenedStyledContent(
        _ initialStyled: any _HTMLStyledContent,
        context: inout PDF.HTML.Context
    ) {
        context.withSavedStyleState { context in
            // Collect all consecutive HTML.Styled layers (avoid existential boxing by only casting to _HTMLStyledContent)
            var styledLayers: [any _HTMLStyledContent] = [initialStyled]

            // Flatten: iterate through nested HTML.Styled wrappers
            var current = initialStyled
            while let nested = current.wrappedStyledContent {
                styledLayers.append(nested)
                current = nested
            }

            // The last element in styledLayers has the innermost non-styled content
            let innermostStyled = styledLayers[styledLayers.count - 1]

            // Apply all styles in order (outermost to innermost),
            // accumulating break flags — any layer requesting a flag wins
            var breakFlags = PDF.HTML.Context.Break.none
            for styled in styledLayers {
                let flags = styled.applyStyle(to: &context)
                if flags.avoidAfter { breakFlags.avoidAfter = true }
                if flags.forceAfter { breakFlags.forceAfter = true }
                if flags.avoidInside { breakFlags.avoidInside = true }
            }

            // Apply CSS Box Model
            // Margin: Apply vertical margins to Y position, horizontal margins to layout bounds
            if let marginTop = context.pdf.marginTop, marginTop > .zero {
                context.pdf.advance(marginTop)
            }
            if let marginLeft = context.pdf.marginLeft {
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + marginLeft
            }
            if let marginRight = context.pdf.marginRight {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - marginRight
            }

            // Padding: Inset the layout box for content
            if let paddingTop = context.pdf.paddingTop, paddingTop > .zero {
                context.pdf.advance(paddingTop)
            }
            if let paddingLeft = context.pdf.paddingLeft {
                context.pdf.layoutBox.llx = context.pdf.layoutBox.llx + paddingLeft
            }
            if let paddingRight = context.pdf.paddingRight {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.urx - paddingRight
            }

            // Explicit width/height constraints
            if let explicitWidth = context.pdf.explicitWidth {
                context.pdf.layoutBox.urx = context.pdf.layoutBox.llx + explicitWidth
            }

            // Handle break-inside: avoid
            if breakFlags.avoidInside {
                let measuredHeight = context.measureContentHeight { ctx in
                    innermostStyled.renderWrappedContent(context: &ctx)
                }

                // If it won't fit on current page but would fit on a fresh page, break before
                let pageContentHeight = context.configuration.content.height
                if context.pdf.page.exceeds(adding: measuredHeight) && measuredHeight <= pageContentHeight {
                    context.pdf.page.new()
                }
            }

            // Handle break-after: avoid (sticky header behavior)
            if breakFlags.avoidAfter {
                let snapshot = PDF.HTML.Context.Snapshot(from: context.pdf)
                let measuredHeight = context.measureContentHeight { ctx in
                    innermostStyled.renderWrappedContent(context: &ctx)
                }

                if let existingDeferred = context.deferredKeepWithNextRender {
                    let combinedHeight = existingDeferred.measuredHeight + measuredHeight
                    context.deferredKeepWithNextRender = PDF.HTML.Context.Deferred(
                        render: { ctx in
                            existingDeferred.render(&ctx)
                            snapshot.restore(to: &ctx.pdf)
                            innermostStyled.renderWrappedContent(context: &ctx)
                            ctx.pdf.flush.inline()
                        },
                        measuredHeight: combinedHeight
                    )
                } else {
                    context.deferredKeepWithNextRender = PDF.HTML.Context.Deferred(
                        render: { ctx in
                            snapshot.restore(to: &ctx.pdf)
                            innermostStyled.renderWrappedContent(context: &ctx)
                            ctx.pdf.flush.inline()
                        },
                        measuredHeight: measuredHeight
                    )
                }
            } else {
                // Normal rendering - render the innermost content
                innermostStyled.renderWrappedContent(context: &context)

                // Handle break-after: always/page
                if breakFlags.forceAfter {
                    context.pdf.flush.inline()
                    context.pdf.page.new()
                }
            }

            // Apply bottom padding and margin after content renders
            if let paddingBottom = context.pdf.paddingBottom, paddingBottom > .zero {
                context.pdf.advance(paddingBottom)
            }
            if let marginBottom = context.pdf.marginBottom, marginBottom > .zero {
                context.pdf.advance(marginBottom)
            }
        }
    }
}

// MARK: - Mirror-Based Type Detection
//
// These predicates identify wrapper types by examining field names via Mirror,
// avoiding `as?` casts that crash on deeply nested generic types (SIGBUS in
// `swift_conformsToProtocolMaybeInstantiateSuperclasses`).
//
// Used by the worklist interpreter's Phase 1 to detect wrappers BEFORE
// Phase 2's `as?` casts.
//
// WORKAROUND: Mirror-based type detection using internal field names
// WHY: as? casts on deeply nested generic types crash with SIGBUS (Swift type metadata instantiation)
// WHEN TO REMOVE: When Swift fixes type metadata instantiation for deeply nested generics

extension PDF.HTML {

    /// Detect `HTML.Styled<Content>` by checking for "content" and "property" fields.
    ///
    /// HTML.Styled wraps content with a CSS property for inline styling.
    /// Structure: `struct Styled<Content> { let content: Content; let property: P? }`
    ///
    /// - Note: HTML._Attributes also has "content" but uses "attributes" instead of "property"
    private static func isStyledType(_ mirror: Mirror) -> Bool {
        var hasContent = false
        var hasProperty = false
        for child in mirror.children {
            if child.label == "content" { hasContent = true }
            if child.label == "property" { hasProperty = true }
            if hasContent && hasProperty { return true }
        }
        return false
    }

    /// Detect `HTML.CSS<Base>` by checking for "base" field (without "renderFunction").
    ///
    /// HTML.CSS wraps content for CSS property chaining (`.css.display().flexDirection()`).
    /// Structure: `struct CSS<Base> { let base: Base }`
    ///
    /// - Note: HTML.AnyView also has "base" but additionally has "renderFunction",
    ///   so we exclude types that have both to avoid misidentification.
    private static func isCSSWrapperType(_ mirror: Mirror) -> Bool {
        var hasBase = false
        var hasRenderFunction = false
        for child in mirror.children {
            if child.label == "base" { hasBase = true }
            if child.label == "renderFunction" { hasRenderFunction = true }
        }
        return hasBase && !hasRenderFunction
    }

    /// Detect `HTML._Attributes<Content>` by checking for "content" and "attributes" fields.
    ///
    /// HTML._Attributes wraps content with HTML attributes (id, class, href, etc.).
    /// Structure: `struct _Attributes<Content> { let content: Content; var attributes: [...] }`
    ///
    /// - Note: HTML.Styled also has "content" but uses "property" instead of "attributes"
    private static func isAttributesType(_ mirror: Mirror) -> Bool {
        var hasContent = false
        var hasAttributes = false
        for child in mirror.children {
            if child.label == "content" { hasContent = true }
            if child.label == "attributes" { hasAttributes = true }
            if hasContent && hasAttributes { return true }
        }
        return false
    }

    /// Detect `_Conditional<First, Second>` by checking for enum display style
    /// and "first" or "second" case labels.
    ///
    /// _Conditional is an enum created by if/else in result builders.
    /// Structure: `enum _Conditional<First, Second> { case first(First); case second(Second) }`
    ///
    /// When branches contain deeply nested generic types (e.g., HTML.Element<TableRow<...>>),
    /// using `as?` casts to detect conditionals can crash with SIGBUS. Mirror-based detection
    /// avoids this by not triggering Swift's type metadata instantiation.
    private static func isConditionalType(_ mirror: Mirror) -> Bool {
        guard mirror.displayStyle == .enum else { return false }
        // Enum cases appear as children with labels "first" or "second"
        for child in mirror.children {
            if child.label == "first" || child.label == "second" {
                return true
            }
        }
        return false
    }

    /// Detect `Optional<Wrapped>` by checking for optional display style.
    ///
    /// Optional is created by `if` without `else` in result builders (buildOptional).
    /// Structure: `enum Optional<Wrapped> { case none; case some(Wrapped) }`
    ///
    /// When the wrapped type is deeply nested (e.g., Optional<TableRow<...>>),
    /// using `as?` casts can crash with SIGBUS. Mirror-based detection avoids this.
    private static func isOptionalType(_ mirror: Mirror) -> Bool {
        return mirror.displayStyle == .optional
    }

    /// Apply a CSS property value to the PDF context.
    ///
    /// Property types are simple value types (FontWeight, Color, Display, etc.),
    /// not deeply nested generic wrappers, so `as?` casts are safe.
    ///
    /// The property may be wrapped in Optional, so we unwrap that first via Mirror.
    private static func applyStylePropertyViaMirror(
        _ prop: Any,
        context: inout PDF.HTML.Context
    ) {
        let unwrapped: Any
        let propMirror = Mirror(reflecting: prop)
        if propMirror.displayStyle == .optional {
            if let firstChild = propMirror.children.first {
                unwrapped = firstChild.value
            } else {
                return
            }
        } else {
            unwrapped = prop
        }

        if let modifier = unwrapped as? any PDF.HTML.Style.Modifier {
            modifier.apply(to: &context.pdf, configuration: context.configuration)
        }

        if let htmlModifier = unwrapped as? any PDF.HTML.Style.Context.Modifier {
            htmlModifier.apply(to: &context)
        }
    }

    /// Dynamic dispatch for type-erased values extracted from Mirror children.
    ///
    /// Delegates to `iterativeDispatch` — same loop, same dispatch logic.
    static func renderInnerContent(
        _ value: Any,
        context: inout PDF.HTML.Context
    ) {
        iterativeDispatch(value, context: &context)
    }
}
