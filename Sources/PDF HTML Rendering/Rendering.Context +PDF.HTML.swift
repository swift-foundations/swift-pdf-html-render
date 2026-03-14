import HTML_Renderable
import PDF_Rendering
import Rendering_Primitives

extension Rendering.Context {
    /// Creates a rendering context that forwards operations to a PDF HTML context.
    ///
    /// - Parameter state: A mutable reference to the PDF HTML rendering state.
    /// - Returns: A witness-based rendering context backed by the PDF HTML context.
    public static func pdfHTML(state: Ownership.Mutable<PDF.HTML.Context>) -> Self {
        .init(
            text: { state.value.text($0) },
            lineBreak: { state.value.lineBreak() },
            thematicBreak: { state.value.thematicBreak() },
            image: { state.value.image(source: $0, alt: $1) },
            pageBreak: { state.value.pageBreak() },
            setAttribute: { state.value.set(attribute: $0, $1) },
            addClass: { state.value.add(class: $0) },
            writeRaw: { state.value.write(raw: $0) },
            registerStyle: { state.value.register(style: $0, atRule: $1, selector: $2, pseudo: $3) },
            applyInlineStyle: { state.value.apply(inlineStyle: $0) },
            pushBlock: { PDF.HTML.Context._pushBlock(&state.value, role: $0, style: $1) },
            popBlock: { PDF.HTML.Context._popBlock(&state.value) },
            pushInline: { PDF.HTML.Context._pushInline(&state.value, role: $0, style: $1) },
            popInline: { PDF.HTML.Context._popInline(&state.value) },
            pushList: { PDF.HTML.Context._pushList(&state.value, kind: $0, start: $1) },
            popList: { PDF.HTML.Context._popList(&state.value) },
            pushItem: { PDF.HTML.Context._pushItem(&state.value) },
            popItem: { PDF.HTML.Context._popItem(&state.value) },
            pushLink: { PDF.HTML.Context._pushLink(&state.value, destination: $0) },
            popLink: { PDF.HTML.Context._popLink(&state.value) },
            pushAttributes: { PDF.HTML.Context._pushAttributes(&state.value) },
            popAttributes: { PDF.HTML.Context._popAttributes(&state.value) },
            pushElement: { PDF.HTML.Context._pushElement(&state.value, tagName: $0, isBlock: $1, isVoid: $2, isPreElement: $3) },
            popElement: { PDF.HTML.Context._popElement(&state.value, isBlock: $0) },
            pushStyle: { PDF.HTML.Context._pushStyle(&state.value) },
            popStyle: { PDF.HTML.Context._popStyle(&state.value) }
        )
    }
}
