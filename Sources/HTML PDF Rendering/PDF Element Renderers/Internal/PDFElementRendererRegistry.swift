import PDF_Rendering
import HTML_Standard

/// Registry for PDF element renderers.
///
/// This registry maps HTML tag names to their corresponding renderer implementations.
/// Custom renderers can be registered to extend or override the default rendering behavior.
///
/// Example:
/// ```swift
/// // Register a custom renderer
/// PDFElementRendererRegistry.shared.register(MyCustomH1Renderer.self)
///
/// // Look up a renderer
/// if let renderer = PDFElementRendererRegistry.shared.renderer(for: "h1") {
///     try renderer.render(tag: "h1", ...)
/// }
/// ```
public final class PDFElementRendererRegistry: @unchecked Sendable {
    /// Shared singleton instance
    public static let shared = PDFElementRendererRegistry()

    /// Storage for registered renderers (protected by actor isolation)
    private var renderers: [String: any PDFElementRenderer.Type] = [:]

    private init() {
        registerBuiltInRenderers()
    }

    /// Registers a renderer for its supported tags.
    ///
    /// If a tag already has a registered renderer, it will be replaced.
    ///
    /// - Parameter renderer: The renderer type to register
    public func register(_ renderer: any PDFElementRenderer.Type) {
        for tag in renderer.supportedTags {
            renderers[tag.lowercased()] = renderer
        }
    }

    /// Returns the renderer for a given tag, if one is registered.
    ///
    /// - Parameter tag: The HTML tag name (case-insensitive)
    /// - Returns: The renderer type, or nil if no renderer is registered
    public func renderer(for tag: String) -> (any PDFElementRenderer.Type)? {
        renderers[tag.lowercased()]
    }

    /// Returns all registered tags.
    public var registeredTags: Set<String> {
        Set(renderers.keys)
    }

    /// Removes all registered renderers.
    ///
    /// Primarily useful for testing.
    public func reset() {
        renderers.removeAll()
        registerBuiltInRenderers()
    }

    /// Registers all built-in element renderers.
    ///
    /// Called during initialization to set up default rendering.
    private func registerBuiltInRenderers() {
        // Void/Simple elements
        register(BR.Renderer.self)
        register(ThematicBreak.Renderer.self)

        // Headings
        register(H1.Renderer.self)
        register(H2.Renderer.self)
        register(H3.Renderer.self)
        register(H4.Renderer.self)
        register(H5.Renderer.self)
        register(H6.Renderer.self)

        // Text formatting - block
        register(Paragraph.Renderer.self)
        register(PreformattedText.Renderer.self)
        register(BlockQuote.Renderer.self)

        // Text formatting - inline
        register(StrongImportance.Renderer.self)
        register(B.Renderer.self)
        register(Emphasis.Renderer.self)
        register(IdiomaticText.Renderer.self)
        register(UnarticulatedAnnotation.Renderer.self)
        register(Strikethrough.Renderer.self)
        register(Code.Renderer.self)
        register(Mark.Renderer.self)
        register(Small.Renderer.self)
        register(Subscript.Renderer.self)
        register(Superscript.Renderer.self)

        // Containers
        register(ContentDivision.Renderer.self)
        register(ContentSpan.Renderer.self)
        register(Section.Renderer.self)
        register(Article.Renderer.self)
        register(Header.Renderer.self)
        register(Footer.Renderer.self)
        register(Main.Renderer.self)
        register(Aside.Renderer.self)
        register(NavigationSection.Renderer.self)

        // Links
        register(Anchor.Renderer.self)

        // Lists
        register(UnorderedList.Renderer.self)
        register(OrderedList.Renderer.self)
        register(ListItem.Renderer.self)

        // Tables
        register(Table.Renderer.self)
        register(TableHead.Renderer.self)
        register(TableBody.Renderer.self)
        register(TableFoot.Renderer.self)
        register(TableRow.Renderer.self)
        register(TableHeader.Renderer.self)
        register(TableDataCell.Renderer.self)
        register(Caption.Renderer.self)

        // Media
        register(Image.Renderer.self)
        register(Figure.Renderer.self)
        register(FigureCaption.Renderer.self)
        register(Picture.Renderer.self)

        // Forms
        register(Form.Renderer.self)
        register(Input.Renderer.self)
        register(Button.Renderer.self)
        register(Select.Renderer.self)
        register(Option.Renderer.self)
        register(Textarea.Renderer.self)
        register(Label.Renderer.self)
        register(FieldSet.Renderer.self)
        register(Legend.Renderer.self)

        // Interactive
        register(Details.Renderer.self)
        register(DisclosureSummary.Renderer.self)
        register(Dialog.Renderer.self)
    }
}
